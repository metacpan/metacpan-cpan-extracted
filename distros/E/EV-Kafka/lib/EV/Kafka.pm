package EV::Kafka;
use strict;
use warnings;
use EV;

BEGIN {
    use XSLoader;
    our $VERSION = '0.01';
    XSLoader::load __PACKAGE__, $VERSION;
}

sub new {
    my ($class, %opts) = @_;

    my $loop = delete $opts{loop};
    my $self = $class->_new($loop);

    # Parse brokers
    my $brokers = delete $opts{brokers} // '127.0.0.1:9092';
    my @bootstrap;
    for my $b (split /,/, $brokers) {
        $b =~ s/^\s+|\s+$//g;
        my ($h, $p) = split /:/, $b, 2;
        $p //= 9092;
        push @bootstrap, [$h, $p + 0];
    }

    # Store config
    my $cfg = {
        bootstrap    => \@bootstrap,
        client_id    => delete $opts{client_id} // 'ev-kafka',
        tls          => delete $opts{tls} // 0,
        tls_ca_file  => delete $opts{tls_ca_file},
        tls_skip_verify => delete $opts{tls_skip_verify} // 0,
        sasl         => delete $opts{sasl},
        on_error     => delete $opts{on_error} // sub { die "EV::Kafka: @_\n" },
        on_connect   => delete $opts{on_connect},
        on_message   => delete $opts{on_message},
        acks         => delete $opts{acks} // -1,
        linger_ms    => delete $opts{linger_ms} // 5,
        batch_size   => delete $opts{batch_size} // 16384,
        partitioner  => delete $opts{partitioner},
        compression      => delete $opts{compression},     # 'lz4', 'gzip', or undef
        idempotent       => delete $opts{idempotent} // 0,
        transactional_id => delete $opts{transactional_id}, # enables transactions
        fetch_max_wait_ms => delete $opts{fetch_max_wait_ms} // 500,
        fetch_max_bytes   => delete $opts{fetch_max_bytes} // 1048576,
        fetch_min_bytes   => delete $opts{fetch_min_bytes} // 1,
        metadata_refresh  => delete $opts{metadata_refresh} // 300,
    };

    # Internal state
    $cfg->{conns}     = {};    # node_id => EV::Kafka::Conn
    $cfg->{meta}      = undef; # latest metadata response
    $cfg->{leaders}   = {};    # "topic:partition" => node_id
    $cfg->{broker_map}= {};    # node_id => {host, port}
    $cfg->{connected} = 0;
    $cfg->{meta_pending} = 0;
    $cfg->{pending_ops} = [];  # ops waiting for metadata

    # Producer state
    $cfg->{batches}  = {};     # "topic:partition" => [{rec, cb}]
    $cfg->{next_sequence} = {}; # "topic:partition" => next sequence number
    $cfg->{producer_id}    = -1;
    $cfg->{producer_epoch} = -1;
    $cfg->{rr_counter} = 0;

    # Consumer state
    $cfg->{assignments} = [];  # [{topic, partition, offset}]
    $cfg->{fetch_active} = 0;
    $cfg->{group} = undef;

    bless { xs => $self, cfg => $cfg }, "${class}::Client";
}

package EV::Kafka::Client;
use EV;
use Scalar::Util 'weaken';

sub _any_conn {
    my ($self) = @_;
    my $cfg = $self->{cfg};
    my $conn = $cfg->{bootstrap_conn};
    for my $c (values %{$cfg->{conns}}) {
        if ($c->connected) { $conn = $c; last }
    }
    return ($conn && $conn->connected) ? $conn : undef;
}

sub _get_or_create_conn {
    my ($self, $node_id) = @_;
    my $cfg = $self->{cfg};
    return $cfg->{conns}{$node_id} if $cfg->{conns}{$node_id};

    my $info = $cfg->{broker_map}{$node_id};
    return undef unless $info;

    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    $self->_configure_conn($conn);

    $cfg->{conns}{$node_id} = $conn;
    weaken(my $weak = $self);
    $conn->on_connect(sub {
        $weak->_drain_pending_for($node_id) if $weak;
    });
    $conn->connect($info->{host}, $info->{port}, 10.0);

    return $conn;
}

sub _configure_conn {
    my ($self, $conn) = @_;
    my $cfg = $self->{cfg};
    $conn->client_id($cfg->{client_id});
    if ($cfg->{tls}) {
        $conn->tls(1, $cfg->{tls_ca_file}, $cfg->{tls_skip_verify});
    }
    if ($cfg->{sasl}) {
        $conn->sasl($cfg->{sasl}{mechanism}, $cfg->{sasl}{username}, $cfg->{sasl}{password});
    }
    weaken(my $weak_cfg = $cfg);
    $conn->on_error(sub {
        $weak_cfg->{on_error}->($_[0]) if $weak_cfg && $weak_cfg->{on_error};
    });
}

sub _bootstrap_connect {
    my ($self, $cb) = @_;
    my $cfg = $self->{cfg};
    my @bs = @{$cfg->{bootstrap}};
    my $idx = 0;

    my $try; $try = sub {
        if ($idx >= @bs) {
            undef $try;
            $cfg->{on_error}->("all bootstrap brokers unreachable") if $cfg->{on_error};
            return;
        }
        my ($host, $port) = @{$bs[$idx++]};
        my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
        $self->_configure_conn($conn);

        $conn->on_error(sub {
            # try next broker
            $try->();
        });

        $conn->on_connect(sub {
            undef $try; # break self-reference cycle
            $conn->on_error(sub {
                $cfg->{on_error}->($_[0]) if $cfg->{on_error};
            });
            $cfg->{bootstrap_conn} = $conn;
            $cfg->{connected} = 1;
            $self->_refresh_metadata($cb);
        });

        $conn->connect($host, $port, 10.0);
    };
    $try->();
}

sub connect {
    my ($self, $cb) = @_;
    $self->_bootstrap_connect($cb);
}

sub _merge_metadata {
    my ($cfg, $meta) = @_;
    for my $b (@{$meta->{brokers} // []}) {
        $cfg->{broker_map}{$b->{node_id}} = {
            host => $b->{host}, port => $b->{port}
        };
    }
    for my $t (@{$meta->{topics} // []}) {
        next if $t->{error_code};
        for my $p (@{$t->{partitions} // []}) {
            $cfg->{leaders}{"$t->{name}:$p->{partition}"} = $p->{leader};
        }
    }
}

sub _refresh_metadata {
    my ($self, $cb) = @_;
    my $cfg = $self->{cfg};
    return if $cfg->{meta_pending};
    $cfg->{meta_pending} = 1;

    my $conn = $self->_any_conn;
    unless ($conn) { $cfg->{meta_pending} = 0; return }

    $conn->metadata(undef, sub {
        my ($meta, $err) = @_;
        $cfg->{meta_pending} = 0;
        if ($err) {
            $cfg->{on_error}->("metadata: $err") if $cfg->{on_error};
            return;
        }

        $cfg->{meta} = $meta;
        _merge_metadata($cfg, $meta);

        # assign bootstrap_conn a node_id if possible
        if ($cfg->{bootstrap_conn} && $meta->{brokers} && @{$meta->{brokers}}) {
            my $binfo = $meta->{brokers}[0];
            $cfg->{conns}{$binfo->{node_id}} //= $cfg->{bootstrap_conn};
        }

        if (($cfg->{idempotent} || $cfg->{transactional_id}) && $cfg->{producer_id} < 0) {
            $self->_init_idempotent(sub {
                $self->_drain_all_pending;
                $cb->($meta) if $cb;
                $cfg->{on_connect}->() if $cfg->{on_connect};
                $cfg->{on_connect} = undef;
            });
        } else {
            $self->_drain_all_pending;
            $cb->($meta) if $cb;
            $cfg->{on_connect}->() if $cfg->{on_connect};
            $cfg->{on_connect} = undef;
        }
    });
}

sub _refresh_metadata_for_topic {
    my ($self, $topic) = @_;
    my $cfg = $self->{cfg};
    return if $cfg->{meta_pending};
    $cfg->{meta_pending} = 1;

    my $conn = $self->_any_conn;
    unless ($conn) { $cfg->{meta_pending} = 0; return }

    $conn->metadata([$topic], sub {
        my ($meta, $err) = @_;
        $cfg->{meta_pending} = 0;
        if ($err) {
            $cfg->{on_error}->("metadata: $err") if $cfg->{on_error};
            return;
        }

        _merge_metadata($cfg, $meta);

        # if topic still has error, retry after delay
        my $topic_ok = 0;
        for my $t (@{$meta->{topics} // []}) {
            if ($t->{name} eq $topic && !$t->{error_code} && @{$t->{partitions} // []}) {
                $topic_ok = 1;
                last;
            }
        }

        if ($topic_ok) {
            $self->_drain_all_pending;
        } else {
            # retry after short delay (topic being created)
            my $t; $t = EV::timer 0.5, 0, sub {
                undef $t;
                $self->_refresh_metadata_for_topic($topic);
            };
        }
    });
}

sub _init_idempotent {
    my ($self, $cb) = @_;
    my $cfg = $self->{cfg};

    my $do_init = sub {
        my ($conn) = @_;
        $conn->init_producer_id($cfg->{transactional_id}, 30000, sub {
            my ($res, $err) = @_;
            if (!$err && $res && !$res->{error_code}) {
                $cfg->{producer_id}    = $res->{producer_id};
                $cfg->{producer_epoch} = $res->{producer_epoch};
            } else {
                my $msg = $err || "InitProducerId error: " . ($res->{error_code} // '?');
                $cfg->{on_error}->($msg) if $cfg->{on_error};
            }
            $cb->() if $cb;
        });
    };

    if ($cfg->{transactional_id}) {
        # transactional: find transaction coordinator first
        my $conn = $self->_any_conn;
        unless ($conn) { $cb->() if $cb; return }

        my $on_coord = sub {
            my ($res, $err) = @_;
            if ($err || ($res->{error_code} && $res->{error_code} != 0)) {
                $do_init->($conn);
                return;
            }
            # connect to the transaction coordinator
            $cfg->{broker_map}{$res->{node_id}} = {
                host => $res->{host}, port => $res->{port}
            };
            my $txn_conn = $self->_get_or_create_conn($res->{node_id});
            if ($txn_conn && $txn_conn->connected) {
                $cfg->{_txn_coordinator} = $txn_conn;
                $do_init->($txn_conn);
            } else {
                push @{$cfg->{pending_ops}}, {
                    node_id => $res->{node_id},
                    run => sub {
                        $cfg->{_txn_coordinator} = $self->_get_or_create_conn($res->{node_id});
                        $do_init->($cfg->{_txn_coordinator} || $conn);
                    },
                };
            }
        };
        $conn->find_coordinator($cfg->{transactional_id}, $on_coord, 1);
    } else {
        # idempotent only: any broker works
        my $conn = $self->_any_conn;
        unless ($conn) { $cb->() if $cb; return }
        $do_init->($conn);
    }
}

sub _drain_pending_for {
    my ($self, $node_id) = @_;
    my $cfg = $self->{cfg};
    my @remaining;
    for my $op (@{$cfg->{pending_ops}}) {
        if (defined $op->{node_id} && $op->{node_id} == $node_id) {
            $op->{run}->();
        } else {
            push @remaining, $op;
        }
    }
    $cfg->{pending_ops} = \@remaining;
}

sub _drain_all_pending {
    my ($self) = @_;
    my $cfg = $self->{cfg};
    my @ops = @{$cfg->{pending_ops}};
    $cfg->{pending_ops} = [];
    for my $op (@ops) {
        if (defined $op->{node_id}) {
            my $conn = $self->_get_or_create_conn($op->{node_id});
            if ($conn && $conn->connected) {
                $op->{run}->();
            } else {
                push @{$cfg->{pending_ops}}, $op;
            }
        } else {
            $op->{run}->();
        }
    }
}

sub _get_leader {
    my ($self, $topic, $partition) = @_;
    return $self->{cfg}{leaders}{"$topic:$partition"};
}

sub _num_partitions {
    my ($self, $topic) = @_;
    my $meta = $self->{cfg}{meta} or return 0;
    for my $t (@{$meta->{topics} // []}) {
        return scalar @{$t->{partitions}} if $t->{name} eq $topic;
    }
    return 0;
}

sub _select_partition {
    my ($self, $topic, $key) = @_;
    my $np = $self->_num_partitions($topic);
    return 0 unless $np > 0;

    my $cfg = $self->{cfg};
    if ($cfg->{partitioner}) {
        return $cfg->{partitioner}->($topic, $key, $np);
    }
    if (defined $key && length $key) {
        return EV::Kafka::_murmur2($key) % $np;
    }
    return $cfg->{rr_counter}++ % $np;
}

# --- Producer ---

sub produce {
    my ($self, $topic, $key, $value, @rest) = @_;
    my $cb;
    my %opts;
    for my $a (@rest) {
        if (ref $a eq 'CODE') { $cb = $a }
        elsif (ref $a eq 'HASH') { %opts = %$a }
    }

    my $cfg = $self->{cfg};

    # ensure we have metadata
    unless ($cfg->{meta}) {
        push @{$cfg->{pending_ops}}, {
            run => sub { $self->produce($topic, $key, $value, @rest) },
        };
        $self->_refresh_metadata unless $cfg->{meta_pending};
        return;
    }

    my $partition = exists $opts{partition}
        ? $opts{partition}
        : $self->_select_partition($topic, $key);

    my $leader_id = $self->_get_leader($topic, $partition);
    unless (defined $leader_id) {
        # topic/partition unknown — request metadata for this topic to trigger auto-creation
        push @{$cfg->{pending_ops}}, {
            run => sub { $self->produce($topic, $key, $value, @rest) },
        };
        $self->_refresh_metadata_for_topic($topic) unless $cfg->{meta_pending};
        return;
    }

    my $conn = $self->_get_or_create_conn($leader_id);
    unless ($conn && $conn->connected) {
        push @{$cfg->{pending_ops}}, {
            node_id => $leader_id,
            run => sub { $self->produce($topic, $key, $value, @rest) },
        };
        return;
    }

    # Accumulate into batch
    my $bkey = "$topic:$partition";
    my $rec = { key => $key, value => $value };
    $rec->{headers} = $opts{headers} if $opts{headers};
    push @{$cfg->{batches}{$bkey} //= []}, { rec => $rec, cb => $cb };

    # Check batch size threshold
    my $batch = $cfg->{batches}{$bkey};
    my $batch_bytes = 0;
    for my $b (@$batch) {
        $batch_bytes += length($b->{rec}{value} // '') + length($b->{rec}{key} // '') + 20;
    }

    if ($batch_bytes >= $cfg->{batch_size}) {
        $self->_flush_batch($topic, $partition, $conn);
    } elsif (!$cfg->{_linger_active}) {
        # start linger timer
        $cfg->{_linger_active} = 1;
        weaken(my $weak = $self);
        $cfg->{_linger_timer} = EV::timer $cfg->{linger_ms} / 1000.0, 0, sub {
            $cfg->{_linger_active} = 0;
            $weak->_flush_all_batches if $weak;
        };
    }
}

sub _flush_batch {
    my ($self, $topic, $partition, $conn) = @_;
    my $cfg = $self->{cfg};
    my $bkey = "$topic:$partition";
    my $batch = delete $cfg->{batches}{$bkey};
    return unless $batch && @$batch;

    my @records = map { $_->{rec} } @$batch;
    my @cbs     = map { $_->{cb} } @$batch;

    my %popts = (acks => $cfg->{acks});
    $popts{compression} = $cfg->{compression} if $cfg->{compression};
    $popts{transactional_id} = $cfg->{transactional_id} if $cfg->{_txn_active};
    my $saved_seq;
    if (defined $cfg->{producer_id} && $cfg->{producer_id} >= 0) {
        $popts{producer_id}    = $cfg->{producer_id};
        $popts{producer_epoch} = $cfg->{producer_epoch};
        $saved_seq = $cfg->{next_sequence}{$bkey} // 0;
        $popts{base_sequence}  = $saved_seq;
        $cfg->{next_sequence}{$bkey} = $saved_seq + scalar @records;
    }

    $self->_add_txn_partition($topic, $partition) if $cfg->{_txn_active};

    # retry count persists on the batch across re-queues
    $cfg->{_batch_retries}{$bkey} //= 3;

    $conn->produce_batch($topic, $partition, \@records, \%popts, sub {
        my ($result, $err) = @_;

        my $retriable = 0;
        if (!$err && $result && ref $result->{topics} eq 'ARRAY') {
            for my $t (@{$result->{topics}}) {
                for my $p (@{$t->{partitions} // []}) {
                    my $ec = $p->{error_code} // 0;
                    $retriable = $ec if $ec == 6 || $ec == 15 || $ec == 16;
                }
            }
        }

        if ($retriable && ($cfg->{_batch_retries}{$bkey} // 0) > 0) {
            $cfg->{_batch_retries}{$bkey}--;
            $cfg->{next_sequence}{$bkey} = $saved_seq if defined $saved_seq;
            if (exists $cfg->{batches}{$bkey}) {
                unshift @{$cfg->{batches}{$bkey}}, @$batch;
            } else {
                $cfg->{batches}{$bkey} = $batch;
            }
            $self->_refresh_metadata unless $cfg->{meta_pending};
            my $rt; $rt = EV::timer 0.5, 0, sub {
                undef $rt;
                $self->_flush_all_batches;
            };
            return;
        }
        delete $cfg->{_batch_retries}{$bkey};

        for my $cb (@cbs) {
            $cb->($result, $err) if $cb;
        }
    });
}

sub _flush_all_batches {
    my ($self) = @_;
    my $cfg = $self->{cfg};
    my $skipped = 0;
    for my $bkey (keys %{$cfg->{batches}}) {
        my ($topic, $partition) = split /:/, $bkey, 2;
        my $leader_id = $self->_get_leader($topic, $partition);
        unless (defined $leader_id) { $skipped++; next }
        my $conn = $self->_get_or_create_conn($leader_id);
        unless ($conn && $conn->connected) { $skipped++; next }
        $self->_flush_batch($topic, $partition, $conn);
    }
    # re-arm timer if batches were skipped (connection not yet ready)
    if ($skipped && keys %{$cfg->{batches}}) {
        $cfg->{_linger_active} = 1;
        weaken(my $weak = $self);
        $cfg->{_linger_timer} = EV::timer 0.1, 0, sub {
            $cfg->{_linger_active} = 0;
            $weak->_flush_all_batches if $weak;
        };
    }
}

sub produce_many {
    my ($self, $messages, $cb) = @_;
    my $remaining = scalar @$messages;
    return $cb->() if $cb && !$remaining;
    my @errors;
    my $acks0 = ($self->{cfg}{acks} == 0);
    for my $msg (@$messages) {
        my ($topic, $key, $value, @rest) = ref $msg eq 'ARRAY' ? @$msg : @{$msg}{qw(topic key value)};
        if ($acks0) {
            $self->produce($topic, $key, $value, @rest);
            --$remaining;
        } else {
            $self->produce($topic, $key, $value, @rest, sub {
                my ($result, $err) = @_;
                push @errors, $err if $err;
                if (--$remaining <= 0 && $cb) {
                    $cb->(@errors ? \@errors : ());
                }
            });
        }
    }
    $cb->(@errors ? \@errors : ()) if $cb && $acks0;
}

sub flush {
    my ($self, $cb) = @_;
    my $cfg = $self->{cfg};

    # flush any accumulated linger batches first
    $self->_flush_all_batches;
    undef $cfg->{_linger_timer};
    $cfg->{_linger_active} = 0;

    # wait for all in-flight produce callbacks across all connections
    my $pending = 0;
    my %seen;
    for my $conn (values %{$cfg->{conns} // {}}) {
        next unless $conn && $conn->connected;
        $pending += $conn->pending;
        $seen{$$conn} = 1;
    }
    if ($cfg->{bootstrap_conn} && $cfg->{bootstrap_conn}->connected
        && !$seen{${$cfg->{bootstrap_conn}}}) {
        $pending += $cfg->{bootstrap_conn}->pending;
    }
    if ($pending == 0) {
        $cb->() if $cb;
        return;
    }
    # poll until pending drains
    my $check; $check = EV::timer 0, 0.01, sub {
        my $p = 0;
        my %s;
        for my $c (values %{$cfg->{conns} // {}}) {
            next unless $c && $c->connected;
            $p += $c->pending;
            $s{$$c} = 1;
        }
        $p += $cfg->{bootstrap_conn}->pending
            if $cfg->{bootstrap_conn} && $cfg->{bootstrap_conn}->connected
            && !$s{${$cfg->{bootstrap_conn}}};
        if ($p == 0) {
            undef $check;
            $cb->() if $cb;
        }
    };
    $cfg->{_flush_timer} = $check;
}

# --- Consumer ---

sub assign {
    my ($self, $partitions) = @_;
    my $cfg = $self->{cfg};
    $cfg->{assignments} = $partitions;
}

sub seek {
    my ($self, $topic, $partition, $offset_or_ts, $cb) = @_;
    # offset_or_ts: integer offset, or -1 (latest), -2 (earliest)
    for my $a (@{$self->{cfg}{assignments}}) {
        if ($a->{topic} eq $topic && $a->{partition} == $partition) {
            if ($offset_or_ts >= 0) {
                $a->{offset} = $offset_or_ts;
                $cb->() if $cb;
            } else {
                # resolve via list_offsets
                my $leader_id = $self->_get_leader($topic, $partition);
                my $conn = defined($leader_id) ? $self->_get_or_create_conn($leader_id) : undef;
                if ($conn && $conn->connected) {
                    $conn->list_offsets($topic, $partition, $offset_or_ts, sub {
                        my ($res, $err) = @_;
                        if (!$err && $res) {
                            my $off = $res->{topics}[0]{partitions}[0]{offset};
                            $a->{offset} = $off if defined $off;
                        }
                        $cb->() if $cb;
                    });
                } else {
                    $cb->() if $cb;
                }
            }
            return;
        }
    }
    $cb->() if $cb;
}

sub poll {
    my ($self, $cb) = @_;
    my $cfg = $self->{cfg};
    return unless @{$cfg->{assignments}};

    unless ($cfg->{meta}) {
        push @{$cfg->{pending_ops}}, {
            run => sub { $self->poll($cb) },
        };
        $self->_refresh_metadata unless $cfg->{meta_pending};
        return;
    }

    # Group assignments by leader for multi-partition fetch
    my %by_leader; # leader_id => { topic => [{partition, offset, assign_ref}] }
    for my $a (@{$cfg->{assignments}}) {
        my $leader_id = $self->_get_leader($a->{topic}, $a->{partition});
        next unless defined $leader_id;
        push @{$by_leader{$leader_id}{$a->{topic}}}, {
            partition => $a->{partition},
            offset    => $a->{offset},
            _assign   => $a,
        };
    }

    my $dispatched = 0;
    for my $leader_id (keys %by_leader) {
        my $conn = $self->_get_or_create_conn($leader_id);
        next unless $conn && $conn->connected;
        $dispatched++;

        # build fetch_multi argument: {topic => [{partition, offset}]}
        my %fetch_arg;
        my %assign_map; # "topic:partition" => assignment ref
        for my $topic (keys %{$by_leader{$leader_id}}) {
            for my $p (@{$by_leader{$leader_id}{$topic}}) {
                push @{$fetch_arg{$topic}}, {
                    partition => $p->{partition},
                    offset    => $p->{offset},
                };
                $assign_map{"$topic:$p->{partition}"} = $p->{_assign};
            }
        }

        $conn->fetch_multi(\%fetch_arg, sub {
            my ($result, $err) = @_;
            $dispatched--;

            if (!$err && $result && ref $result->{topics} eq 'ARRAY') {
                for my $t (@{$result->{topics}}) {
                    for my $p (@{$t->{partitions} // []}) {
                        my $records = $p->{records} // [];
                        for my $r (@$records) {
                            if ($cfg->{on_message}) {
                                $cfg->{on_message}->(
                                    $t->{topic}, $p->{partition},
                                    $r->{offset}, $r->{key}, $r->{value},
                                    $r->{headers}
                                );
                            }
                        }
                        if (@$records) {
                            my $a = $assign_map{"$t->{topic}:$p->{partition}"};
                            $a->{offset} = $records->[-1]{offset} + 1 if $a;
                        }
                    }
                }
            }

            $cb->() if $cb && $dispatched <= 0;
        });
    }
    $cb->() if $cb && !$dispatched;
}

sub offsets_for {
    my ($self, $topic, $cb) = @_;
    my $cfg = $self->{cfg};

    my $np = $self->_num_partitions($topic);
    return $cb->({}) if $cb && !$np;

    my $result = {};
    my $remaining = $np;
    for my $p (0..$np-1) {
        my $pid = $p;
        my $leader_id = $self->_get_leader($topic, $pid);
        my $conn = defined($leader_id) ? $self->_get_or_create_conn($leader_id) : undef;
        unless ($conn && $conn->connected) {
            $result->{$pid} = {};
            $cb->($result) if $cb && --$remaining <= 0;
            next;
        }
        my %pdata;
        my $pdone = 0;
        for my $ts (-2, -1) {
            $conn->list_offsets($topic, $pid, $ts, sub {
                my ($res, $err) = @_;
                if (!$err && $res && ref $res->{topics} eq 'ARRAY') {
                    my $off = $res->{topics}[0]{partitions}[0]{offset};
                    if ($ts == -2) { $pdata{earliest} = $off }
                    else           { $pdata{latest}   = $off }
                }
                if (++$pdone == 2) {
                    $result->{$pid} = \%pdata;
                    $cb->($result) if $cb && --$remaining <= 0;
                }
            });
        }
    }
}

sub lag {
    my ($self, $cb) = @_;
    my $cfg = $self->{cfg};
    my @assignments = @{$cfg->{assignments} // []};
    return $cb->({}) if $cb && !@assignments;

    my $result = {};
    my $remaining = scalar @assignments;
    for my $a (@assignments) {
        my $key = "$a->{topic}:$a->{partition}";
        my $leader_id = $self->_get_leader($a->{topic}, $a->{partition});
        my $conn = defined($leader_id) ? $self->_get_or_create_conn($leader_id) : undef;
        if ($conn && $conn->connected) {
            $conn->list_offsets($a->{topic}, $a->{partition}, -1, sub {
                my ($res, $err) = @_;
                my $hw = 0;
                if (!$err && $res && ref $res->{topics} eq 'ARRAY') {
                    $hw = $res->{topics}[0]{partitions}[0]{offset} // 0;
                }
                $result->{$key} = {
                    current  => $a->{offset},
                    latest   => $hw,
                    lag      => $hw - $a->{offset},
                };
                $cb->($result) if $cb && --$remaining <= 0;
            });
        } else {
            $result->{$key} = { current => $a->{offset}, latest => 0, lag => 0 };
            $cb->($result) if $cb && --$remaining <= 0;
        }
    }
}

sub error_name {
    shift if ref $_[0]; # allow $kafka->error_name or EV::Kafka::Client::error_name
    return EV::Kafka::_error_name($_[0]);
}

# --- Consumer Group ---

sub subscribe {
    my ($self, @args) = @_;
    my @topics;
    my %opts;

    # subscribe('topic1', 'topic2', group_id => 'g', ...)
    while (@args) {
        if ($args[0] =~ /^(group_id|group_instance_id|on_assign|on_revoke|session_timeout|rebalance_timeout|heartbeat_interval|auto_commit|auto_offset_reset)$/) {
            my $k = shift @args;
            $opts{$k} = shift @args;
        } else {
            push @topics, shift @args;
        }
    }

    my $cfg = $self->{cfg};
    my $group_id = $opts{group_id} or die "group_id required";

    $cfg->{group} = {
        group_id    => $group_id,
        member_id   => '',
        generation  => -1,
        topics      => \@topics,
        on_assign   => $opts{on_assign},
        on_revoke   => $opts{on_revoke},
        session_timeout    => $opts{session_timeout} // 30000,
        rebalance_timeout  => $opts{rebalance_timeout} // 60000,
        heartbeat_interval => $opts{heartbeat_interval} // 3,
        auto_commit => $opts{auto_commit} // 1,
        auto_offset_reset  => $opts{auto_offset_reset} // 'earliest',
        group_instance_id  => $opts{group_instance_id},
        coordinator => undef,
        heartbeat_timer => undef,
        state       => 'init',
    };

    # Step 1: ensure we have metadata
    unless ($cfg->{meta}) {
        push @{$cfg->{pending_ops}}, {
            run => sub { $self->_group_start },
        };
        $self->_refresh_metadata unless $cfg->{meta_pending};
        return;
    }

    $self->_group_start;
}

sub _group_start {
    my ($self) = @_;
    my $cfg = $self->{cfg};
    my $g = $cfg->{group} or return;

    my $conn = $self->_any_conn;
    return unless $conn;

    $g->{state} = 'finding';
    $conn->find_coordinator($g->{group_id}, sub {
        my ($res, $err) = @_;
        if ($err || $res->{error_code}) {
            my $msg = $err || "FindCoordinator error: $res->{error_code}";
            $cfg->{on_error}->($msg) if $cfg->{on_error};
            # retry after delay
            my $t; $t = EV::timer 1, 0, sub { undef $t; $self->_group_start };
            return;
        }

        # Store coordinator info and connect
        $cfg->{broker_map}{$res->{node_id}} = {
            host => $res->{host}, port => $res->{port}
        };
        my $coord = $self->_get_or_create_conn($res->{node_id});
        $g->{coordinator} = $coord;
        $g->{coordinator_id} = $res->{node_id};

        if ($coord->connected) {
            $self->_group_join;
        } else {
            push @{$cfg->{pending_ops}}, {
                node_id => $res->{node_id},
                run => sub { $self->_group_join },
            };
        }
    });
}

sub _group_join {
    my ($self) = @_;
    my $cfg = $self->{cfg};
    my $g = $cfg->{group} or return;
    my $coord = $g->{coordinator} or return;

    $g->{state} = 'joining';
    $coord->join_group(
        $g->{group_id}, $g->{member_id},
        $g->{topics}, sub {
            my ($res, $err) = @_;
            if ($err) {
                $cfg->{on_error}->("JoinGroup: $err") if $cfg->{on_error};
                return;
            }

            if ($res->{error_code} == 15 || $res->{error_code} == 16) {
                # COORDINATOR_NOT_AVAILABLE / NOT_COORDINATOR — re-discover
                my $t; $t = EV::timer 1, 0, sub { undef $t; $self->_group_start };
                return;
            }
            if ($res->{error_code} == 27) {
                # REBALANCE_IN_PROGRESS — retry
                my $t; $t = EV::timer 1, 0, sub { undef $t; $self->_group_join };
                return;
            }
            if ($res->{error_code} == 79) {
                # MEMBER_ID_REQUIRED — retry with assigned member_id
                $g->{member_id} = $res->{member_id} if $res->{member_id};
                $self->_group_join;
                return;
            }
            if ($res->{error_code}) {
                $cfg->{on_error}->("JoinGroup error: $res->{error_code}") if $cfg->{on_error};
                return;
            }

            $g->{member_id}  = $res->{member_id};
            $g->{generation} = $res->{generation_id};
            my $is_leader = ($res->{leader} eq $res->{member_id});

            # Build assignments (if leader)
            my $assignments = [];
            if ($is_leader && $res->{members} && @{$res->{members}}) {
                $assignments = $self->_assign_partitions($res->{members}, $g->{topics});
            }

            $self->_group_sync($assignments);
        },
        $g->{session_timeout}, $g->{rebalance_timeout},
        $g->{group_instance_id}
    );
}

sub _assign_partitions {
    my ($self, $members, $topics) = @_;
    my $cfg = $self->{cfg};
    my $meta = $cfg->{meta} or return [];

    my @all_parts;
    for my $t (@{$meta->{topics} // []}) {
        my $tname = $t->{name};
        next unless grep { $_ eq $tname } @$topics;
        for my $p (@{$t->{partitions} // []}) {
            push @all_parts, { topic => $tname, partition => $p->{partition} };
        }
    }
    @all_parts = sort { $a->{topic} cmp $b->{topic} || $a->{partition} <=> $b->{partition} } @all_parts;

    my @member_ids = sort map { $_->{member_id} } @$members;
    my $nm = scalar @member_ids;

    # Sticky assignment: preserve previous assignments where possible
    my $prev = $cfg->{_prev_assignments} // {};
    my %member_parts; # member_id => [@parts]
    my %assigned;      # "topic:partition" => 1

    my $max_per = int(@all_parts / $nm) + ((@all_parts % $nm) ? 1 : 0);

    # Step 1: keep valid previous assignments (but cap at max_per)
    for my $mid (@member_ids) {
        $member_parts{$mid} = [];
        for my $p (@{$prev->{$mid} // []}) {
            my $key = "$p->{topic}:$p->{partition}";
            if (grep { $_->{topic} eq $p->{topic} && $_->{partition} == $p->{partition} } @all_parts) {
                if (scalar @{$member_parts{$mid}} < $max_per) {
                    push @{$member_parts{$mid}}, $p;
                    $assigned{$key} = 1;
                }
            }
        }
    }

    # Step 2: distribute unassigned partitions to least-loaded members
    my @unassigned = grep { !$assigned{"$_->{topic}:$_->{partition}"} } @all_parts;
    for my $p (@unassigned) {
        my $min_mid = $member_ids[0];
        my $min_count = scalar @{$member_parts{$min_mid}};
        for my $mid (@member_ids) {
            if (scalar @{$member_parts{$mid}} < $min_count) {
                $min_count = scalar @{$member_parts{$mid}};
                $min_mid = $mid;
            }
        }
        push @{$member_parts{$min_mid}}, $p;
    }

    # Save for next rebalance
    $cfg->{_prev_assignments} = { %member_parts };

    # Encode assignments
    my @assignments;
    for my $mid (@member_ids) {
        my %by_topic;
        for my $p (@{$member_parts{$mid}}) {
            push @{$by_topic{$p->{topic}}}, $p->{partition};
        }

        my $buf = '';
        $buf .= pack('n', 0); # version
        $buf .= pack('N', scalar keys %by_topic);
        for my $t (sort keys %by_topic) {
            $buf .= pack('n', length($t)) . $t;
            $buf .= pack('N', scalar @{$by_topic{$t}});
            for my $pid (@{$by_topic{$t}}) {
                $buf .= pack('N', $pid);
            }
        }
        $buf .= pack('N', -1); # user_data = null

        push @assignments, {
            member_id  => $mid,
            assignment => $buf,
        };
    }

    return \@assignments;
}

sub _group_sync {
    my ($self, $assignments) = @_;
    my $cfg = $self->{cfg};
    my $g = $cfg->{group} or return;
    my $coord = $g->{coordinator} or return;

    $g->{state} = 'syncing';
    my $sync_cb = sub {
            my ($res, $err) = @_;
            if ($err) {
                $cfg->{on_error}->("SyncGroup: $err") if $cfg->{on_error};
                return;
            }
            if ($res->{error_code} == 27) {
                # REBALANCE_IN_PROGRESS — rejoin
                my $t; $t = EV::timer 1, 0, sub { undef $t; $self->_group_join };
                return;
            }
            if ($res->{error_code}) {
                $cfg->{on_error}->("SyncGroup error: $res->{error_code}") if $cfg->{on_error};
                return;
            }

            # Decode assignment
            my $data = $res->{assignment} // '';
            my $dlen = length $data;
            my @my_assignments;
            if ($dlen >= 6) {
                my $off = 2; # skip version
                my $tc = unpack('N', substr($data, $off, 4)); $off += 4;
                for my $i (0..$tc-1) {
                    last unless $off + 2 <= $dlen;
                    my $tlen = unpack('n', substr($data, $off, 2)); $off += 2;
                    last unless $off + $tlen <= $dlen;
                    my $tname = substr($data, $off, $tlen); $off += $tlen;
                    last unless $off + 4 <= $dlen;
                    my $pc = unpack('N', substr($data, $off, 4)); $off += 4;
                    for my $j (0..$pc-1) {
                        last unless $off + 4 <= $dlen;
                        my $pid = unpack('N', substr($data, $off, 4)); $off += 4;
                        my $reset = ($g->{auto_offset_reset} // 'earliest') eq 'latest' ? -1 : -2;
                        push @my_assignments, {
                            topic => $tname, partition => $pid, offset => $reset
                        };
                    }
                }
            }

            $g->{state} = 'stable';

            # Fetch committed offsets, then start consuming
            $self->_fetch_committed_offsets(\@my_assignments, sub {
                $cfg->{assignments} = \@my_assignments;

                # Fire on_assign
                $g->{on_assign}->(\@my_assignments) if $g->{on_assign};

                # Start heartbeat
                $self->_start_heartbeat;

                # Start fetch loop
                $self->_start_fetch_loop;
            });
    };
    $coord->sync_group(
        $g->{group_id}, $g->{generation}, $g->{member_id},
        $assignments, $sync_cb, $g->{group_instance_id}
    );
}

sub _fetch_committed_offsets {
    my ($self, $assignments, $cb) = @_;
    my $cfg = $self->{cfg};
    my $g = $cfg->{group} or return $cb->();
    my $coord = $g->{coordinator};
    return $cb->() unless $coord && $coord->connected && @$assignments;

    # Build topics array for offset_fetch
    my %by_topic;
    for my $a (@$assignments) {
        push @{$by_topic{$a->{topic}}}, $a->{partition};
    }
    my @topics;
    for my $t (sort keys %by_topic) {
        push @topics, { topic => $t, partitions => $by_topic{$t} };
    }

    $coord->offset_fetch($g->{group_id}, \@topics, sub {
        my ($res, $err) = @_;
        if (!$err && $res && ref $res->{topics} eq 'ARRAY') {
            for my $t (@{$res->{topics}}) {
                for my $p (@{$t->{partitions} // []}) {
                    next if $p->{error_code};
                    next if $p->{offset} < 0; # no committed offset
                    for my $a (@$assignments) {
                        if ($a->{topic} eq $t->{topic} && $a->{partition} == $p->{partition}) {
                            $a->{offset} = $p->{offset};
                        }
                    }
                }
            }
        }

        # For partitions with unresolved offset (-2=earliest, -1=latest), resolve via ListOffsets
        my @need_offsets = grep { $_->{offset} < 0 } @$assignments;
        if (@need_offsets) {
            my $remaining = scalar @need_offsets;
            for my $a (@need_offsets) {
                my $leader_id = $self->_get_leader($a->{topic}, $a->{partition});
                my $lconn = defined($leader_id) ? $self->_get_or_create_conn($leader_id) : undef;
                if ($lconn && $lconn->connected) {
                    $lconn->list_offsets($a->{topic}, $a->{partition}, $a->{offset}, sub {
                        my ($lres, $lerr) = @_;
                        if (!$lerr && $lres && ref $lres->{topics} eq 'ARRAY') {
                            for my $lt (@{$lres->{topics}}) {
                                for my $lp (@{$lt->{partitions} // []}) {
                                    $a->{offset} = $lp->{offset} if !$lp->{error_code};
                                }
                            }
                        }
                        $remaining--;
                        $cb->() if $remaining <= 0;
                    });
                } else {
                    $a->{offset} = 0;
                    $remaining--;
                    $cb->() if $remaining <= 0;
                }
            }
        } else {
            $cb->();
        }
    });
}

sub _start_heartbeat {
    my ($self) = @_;
    my $cfg = $self->{cfg};
    my $g = $cfg->{group} or return;

    $g->{heartbeat_timer} = EV::timer $g->{heartbeat_interval}, $g->{heartbeat_interval}, sub {
        return unless $g->{state} eq 'stable';
        my $coord = $g->{coordinator};
        return unless $coord && $coord->connected;

        $coord->heartbeat($g->{group_id}, $g->{generation}, $g->{member_id}, sub {
            my ($res, $err) = @_;
            if ($err) { return }
            if ($res && $res->{error_code} == 27) {
                # REBALANCE_IN_PROGRESS
                $g->{state} = 'rebalancing';
                $g->{on_revoke}->($cfg->{assignments}) if $g->{on_revoke};
                $self->_stop_heartbeat;
                $self->_stop_fetch_loop;
                $self->_group_join;
            }
        }, $g->{group_instance_id});
    };
}

sub _stop_heartbeat {
    my ($self) = @_;
    my $g = $self->{cfg}{group} or return;
    undef $g->{heartbeat_timer};
}

sub _start_fetch_loop {
    my ($self) = @_;
    my $cfg = $self->{cfg};
    return if $cfg->{fetch_active};
    $cfg->{fetch_active} = 1;

    $cfg->{fetch_timer} = EV::timer 0, 0.1, sub {
        return unless $cfg->{fetch_active};
        $self->poll;
    };
}

sub _stop_fetch_loop {
    my ($self) = @_;
    my $cfg = $self->{cfg};
    $cfg->{fetch_active} = 0;
    undef $cfg->{fetch_timer};
}

sub commit {
    my ($self, $cb) = @_;
    my $cfg = $self->{cfg};
    my $g = $cfg->{group};
    unless ($g) { $cb->() if $cb; return }
    my $coord = $g->{coordinator};
    unless ($coord && $coord->connected) { $cb->() if $cb; return }

    # Build offset commit data from current assignments
    my %by_topic;
    for my $a (@{$cfg->{assignments} // []}) {
        push @{$by_topic{$a->{topic}}}, {
            partition => $a->{partition},
            offset    => $a->{offset},
        };
    }

    my @topics;
    for my $t (sort keys %by_topic) {
        push @topics, { topic => $t, partitions => $by_topic{$t} };
    }

    if (!@topics) { $cb->() if $cb; return }

    $coord->offset_commit($g->{group_id}, $g->{generation}, $g->{member_id}, \@topics, sub {
        my ($res, $err) = @_;
        $cb->($err) if $cb;
    });
}

sub unsubscribe {
    my ($self, $cb) = @_;
    my $cfg = $self->{cfg};
    my $g = $cfg->{group};

    $self->_stop_heartbeat;
    $self->_stop_fetch_loop;

    my $finish = sub {
        # send LeaveGroup to coordinator for fast rebalance
        if ($g && $g->{coordinator} && $g->{coordinator}->connected && $g->{member_id}) {
            $g->{coordinator}->leave_group($g->{group_id}, $g->{member_id}, sub {
                $cfg->{assignments} = [];
                $cfg->{group} = undef;
                $cb->() if $cb;
            });
        } else {
            $cfg->{assignments} = [];
            $cfg->{group} = undef;
            $cb->() if $cb;
        }
    };

    if ($g && $g->{auto_commit}) {
        $self->commit(sub { $finish->() });
    } else {
        $finish->();
    }
}

# --- Transactions ---

sub begin_transaction {
    my ($self) = @_;
    my $cfg = $self->{cfg};
    die "transactional_id required" unless $cfg->{transactional_id};
    die "producer_id not initialized" unless defined $cfg->{producer_id} && $cfg->{producer_id} >= 0;
    $cfg->{_txn_active} = 1;
    $cfg->{_txn_partitions} = {}; # "topic:partition" => 1
}

sub _txn_conn {
    my ($self) = @_;
    my $cfg = $self->{cfg};
    my $conn = $cfg->{_txn_coordinator};
    return $conn if $conn && $conn->connected;
    return $self->_any_conn;
}

sub _add_txn_partition {
    my ($self, $topic, $partition) = @_;
    my $cfg = $self->{cfg};
    return unless $cfg->{_txn_active};
    my $key = "$topic:$partition";
    return if $cfg->{_txn_partitions}{$key}++;

    my $conn = $self->_txn_conn;
    return unless $conn;

    $conn->add_partitions_to_txn(
        $cfg->{transactional_id}, $cfg->{producer_id},
        $cfg->{producer_epoch},
        [{ topic => $topic, partitions => [$partition] }],
        sub {}
    );
}

sub commit_transaction {
    my ($self, $cb) = @_;
    my $cfg = $self->{cfg};
    die "no active transaction" unless $cfg->{_txn_active};

    # flush all pending batches first
    $self->flush(sub {
        my $conn = $self->_txn_conn;
        unless ($conn) { $cb->(undef) if $cb; return }

        $conn->end_txn($cfg->{transactional_id}, $cfg->{producer_id},
            $cfg->{producer_epoch}, 1, sub {
                my ($res, $err) = @_;
                $cfg->{_txn_active} = 0;
                $cfg->{_txn_partitions} = {};
                $cb->($res, $err) if $cb;
            });
    });
}

sub send_offsets_to_transaction {
    my ($self, $group_id, $cb) = @_;
    my $cfg = $self->{cfg};
    die "no active transaction" unless $cfg->{_txn_active};
    die "transactional_id required" unless $cfg->{transactional_id};

    # gather current consumer offsets
    my %by_topic;
    for my $a (@{$cfg->{assignments} // []}) {
        push @{$by_topic{$a->{topic}}}, {
            partition => $a->{partition},
            offset    => $a->{offset},
        };
    }

    my @topics;
    for my $t (sort keys %by_topic) {
        push @topics, { topic => $t, partitions => $by_topic{$t} };
    }

    unless (@topics) {
        $cb->() if $cb;
        return;
    }

    my $conn = $self->_txn_conn;
    unless ($conn) { $cb->() if $cb; return }

    my $g = $cfg->{group};
    my $generation = $g ? $g->{generation} : -1;
    my $member_id  = $g ? ($g->{member_id} // '') : '';

    $conn->txn_offset_commit(
        $cfg->{transactional_id}, $group_id,
        $cfg->{producer_id}, $cfg->{producer_epoch},
        $generation, $member_id,
        \@topics, sub {
            my ($res, $err) = @_;
            $cb->($res, $err) if $cb;
        }
    );
}

sub abort_transaction {
    my ($self, $cb) = @_;
    my $cfg = $self->{cfg};
    die "no active transaction" unless $cfg->{_txn_active};

    # discard unsent batches — they must not reach the broker after abort
    $cfg->{batches} = {};
    undef $cfg->{_linger_timer};
    $cfg->{_linger_active} = 0;

    my $conn = $self->_txn_conn;
    unless ($conn) { $cb->(undef) if $cb; return }

    $conn->end_txn($cfg->{transactional_id}, $cfg->{producer_id},
        $cfg->{producer_epoch}, 0, sub {
            my ($res, $err) = @_;
            $cfg->{_txn_active} = 0;
            $cfg->{_txn_partitions} = {};
            $cb->($res, $err) if $cb;
        });
}

sub close {
    my ($self, $cb) = @_;
    my $cfg = $self->{cfg} or return;

    $self->_stop_heartbeat;
    $self->_stop_fetch_loop;

    for my $conn (values %{$cfg->{conns} // {}}) {
        eval { $conn->disconnect if $conn && $conn->connected };
    }
    if ($cfg->{bootstrap_conn}) {
        eval { $cfg->{bootstrap_conn}->disconnect
            if $cfg->{bootstrap_conn}->connected };
    }
    $cfg->{conns} = {};
    $cfg->{bootstrap_conn} = undef;
    $cb->() if $cb;
}

sub DESTROY {
    my $self = shift;
    return unless $self && $self->{cfg};
    $self->close;
}

package EV::Kafka::Conn;

1;

=head1 NAME

EV::Kafka - High-performance asynchronous Kafka/Redpanda client using EV

=head1 SYNOPSIS

    use EV::Kafka;

    my $kafka = EV::Kafka->new(
        brokers  => '127.0.0.1:9092',
        acks     => -1,
        on_error => sub { warn "kafka: @_" },
        on_message => sub {
            my ($topic, $partition, $offset, $key, $value, $headers) = @_;
            print "$topic:$partition @ $offset  $key = $value\n";
        },
    );

    # Producer
    $kafka->connect(sub {
        $kafka->produce('my-topic', 'key', 'value', sub {
            my ($result, $err) = @_;
            say "produced at offset " . $result->{topics}[0]{partitions}[0]{base_offset};
        });
    });

    # Consumer (manual assignment)
    $kafka->assign([{ topic => 'my-topic', partition => 0, offset => 0 }]);
    my $poll = EV::timer 0, 0.1, sub { $kafka->poll };

    # Consumer group
    $kafka->subscribe('my-topic',
        group_id  => 'my-group',
        on_assign => sub { ... },
        on_revoke => sub { ... },
    );

    EV::run;

=head1 DESCRIPTION

EV::Kafka is a high-performance asynchronous Kafka client that implements
the Kafka binary protocol in XS with L<EV> event loop integration. It
targets Redpanda and Apache Kafka (protocol version 0.11+).

Two-layer architecture:

=over

=item * B<EV::Kafka::Conn> (XS) -- single broker TCP connection with
protocol encoding/decoding, correlation ID matching, pipelining,
optional TLS and SASL/PLAIN authentication.

=item * B<EV::Kafka::Client> (Perl) -- cluster management with metadata
discovery, broker connection pooling, partition leader routing, producer
with key-based partitioning, consumer with manual assignment or consumer
groups.

=back

Features:

=over

=item * Binary protocol implemented in pure XS (no librdkafka dependency)

=item * Automatic request pipelining per broker connection

=item * Metadata-driven partition leader routing

=item * Producer: acks modes (-1/0/1), key-based partitioning (murmur2),
headers, fire-and-forget (acks=0)

=item * Consumer: manual partition assignment, offset tracking, poll-based
message delivery

=item * Consumer groups: JoinGroup/SyncGroup/Heartbeat, sticky
partition assignment, offset commit/fetch, automatic rebalancing

=item * TLS (OpenSSL) and SASL/PLAIN authentication

=item * Automatic reconnection at the connection layer

=item * Bootstrap broker failover (tries all listed brokers)

=back

=head1 ANYEVENT INTEGRATION

L<AnyEvent> has EV as one of its backends, so EV::Kafka can be used
in AnyEvent applications seamlessly.

=head1 NO UTF-8 SUPPORT

This module handles all values as bytes. Encode your UTF-8 strings
before passing them:

    use Encode;

    $kafka->produce($topic, $key, encode_utf8($val), sub { ... });

=head1 CLUSTER CLIENT METHODS

=head2 new(%options)

Create a new EV::Kafka client. Returns a blessed C<EV::Kafka::Client>
object.

    my $kafka = EV::Kafka->new(
        brokers  => '10.0.0.1:9092,10.0.0.2:9092',
        acks     => -1,
        on_error => sub { warn @_ },
    );

Options:

=over

=item brokers => 'Str'

Comma-separated list of bootstrap broker addresses (host:port).
Default: C<127.0.0.1:9092>.

=item client_id => 'Str' (default 'ev-kafka')

Client identifier sent to brokers.

=item tls => Bool

Enable TLS encryption.

=item tls_ca_file => 'Str'

Path to CA certificate file for TLS verification.

=item tls_skip_verify => Bool

Skip TLS certificate verification.

=item sasl => \%opts

Enable SASL authentication. Supports PLAIN mechanism:

    sasl => { mechanism => 'PLAIN', username => 'user', password => 'pass' }

=item acks => Int (default -1)

Producer acknowledgment mode. C<-1> = all in-sync replicas, C<0> = no
acknowledgment (fire-and-forget), C<1> = leader only.

=item linger_ms => Int (default 5)

Time in milliseconds to accumulate records before flushing a batch.
Lower values reduce latency; higher values improve throughput.

=item batch_size => Int (default 16384)

Maximum batch size in bytes before a batch is flushed immediately.

=item compression => 'Str'

Compression type for produce batches: C<'lz4'> (requires liblz4),
C<'gzip'> (requires zlib), or C<undef> for none.

=item idempotent => Bool (default 0)

Enable idempotent producer. Calls C<InitProducerId> on connect and
sets producer_id/epoch/sequence in each RecordBatch for exactly-once
delivery (broker-side deduplication).

=item transactional_id => 'Str'

Enable transactional producer. Implies idempotent. Required for
C<begin_transaction>/C<commit_transaction>/C<abort_transaction>
and C<send_offsets_to_transaction> (full EOS).

=item partitioner => $cb->($topic, $key, $num_partitions)

Custom partition selection function. Default: murmur2 hash of key,
or round-robin for null keys.

=item on_error => $cb->($errstr)

Error callback. Default: C<die>.

=item on_connect => $cb->()

Called once after initial metadata fetch completes.

=item on_message => $cb->($topic, $partition, $offset, $key, $value, $headers)

Message delivery callback for consumer operations.

=item fetch_max_wait_ms => Int (default 500)

Maximum time the broker waits for C<fetch_min_bytes> of data.

=item fetch_max_bytes => Int (default 1048576)

Maximum bytes per fetch response.

=item fetch_min_bytes => Int (default 1)

Minimum bytes before the broker responds to a fetch.

=item metadata_refresh => Int (default 300)

Metadata refresh interval in seconds (reserved, not yet wired).

=item loop => EV::Loop

EV loop to use. Default: C<EV::default_loop>.

=back

=head2 connect($cb)

Connect to the cluster. Connects to the first available bootstrap
broker, fetches cluster metadata, then fires C<$cb->($metadata)>.

    $kafka->connect(sub {
        my $meta = shift;
        # $meta->{brokers}, $meta->{topics}
    });

=head2 produce($topic, $key, $value, [\%opts,] [$cb])

Produce a message. Routes to the correct partition leader automatically.

    # with callback (acks=1 or acks=-1)
    $kafka->produce('topic', 'key', 'value', sub {
        my ($result, $err) = @_;
    });

    # with headers
    $kafka->produce('topic', 'key', 'value',
        { headers => { 'h1' => 'v1' } }, sub { ... });

    # fire-and-forget (acks=0)
    $kafka->produce('topic', 'key', 'value');

    # explicit partition
    $kafka->produce('topic', 'key', 'value',
        { partition => 3 }, sub { ... });

=head2 produce_many(\@messages, $cb)

Produce multiple messages with a single completion callback. Each
message is an arrayref C<[$topic, $key, $value]> or a hashref
C<{topic, key, value}>. C<$cb> fires when all messages are acknowledged.

    $kafka->produce_many([
        ['my-topic', 'k1', 'v1'],
        ['my-topic', 'k2', 'v2'],
    ], sub {
        my $errors = shift;
        warn "some failed: @$errors" if $errors;
    });

=head2 flush([$cb])

Flush all accumulated produce batches and wait for all in-flight
requests to complete. C<$cb> fires when all pending responses have
been received.

=head2 assign(\@partitions)

Manually assign partitions for consuming.

    $kafka->assign([
        { topic => 'my-topic', partition => 0, offset => 0 },
        { topic => 'my-topic', partition => 1, offset => 100 },
    ]);

=head2 seek($topic, $partition, $offset, [$cb])

Seek a partition to a specific offset. Use C<-2> for earliest, C<-1>
for latest. Updates the assignment in-place.

    $kafka->seek('my-topic', 0, -1, sub { print "at latest\n" });

=head2 offsets_for($topic, $cb)

Get earliest and latest offsets for all partitions of a topic.

    $kafka->offsets_for('my-topic', sub {
        my $offsets = shift;
        # { 0 => { earliest => 0, latest => 42 }, 1 => ... }
    });

=head2 lag($cb)

Get consumer lag for all assigned partitions.

    $kafka->lag(sub {
        my $lag = shift;
        # { "topic:0" => { current => 10, latest => 42, lag => 32 } }
    });

=head2 error_name($code)

Convert a Kafka numeric error code to its name.

    EV::Kafka::Client::error_name(3)  # "UNKNOWN_TOPIC_OR_PARTITION"

=head2 poll([$cb])

Fetch messages from assigned partitions. Calls C<on_message> for each
received record. C<$cb> fires when all fetch responses have arrived.

    my $timer = EV::timer 0, 0.1, sub { $kafka->poll };

=head2 subscribe($topic, ..., %opts)

Join a consumer group and subscribe to topics. The group protocol
handles partition assignment automatically.

    $kafka->subscribe('topic-a', 'topic-b',
        group_id           => 'my-group',
        session_timeout    => 30000,      # ms
        rebalance_timeout  => 60000,      # ms
        heartbeat_interval => 3,          # seconds
        auto_commit        => 1,          # commit on unsubscribe (default)
        auto_offset_reset  => 'earliest', # or 'latest'
        group_instance_id  => 'pod-abc', # KIP-345 static membership
        on_assign => sub {
            my $partitions = shift;
            # [{topic, partition, offset}, ...]
        },
        on_revoke => sub {
            my $partitions = shift;
        },
    );

=head2 commit([$cb])

Commit current consumer offsets to the group coordinator.

    $kafka->commit(sub {
        my $err = shift;
        warn "commit failed: $err" if $err;
    });

=head2 unsubscribe([$cb])

Leave the consumer group (sends LeaveGroup for fast rebalance),
stop heartbeat and fetch loop. If C<auto_commit> is enabled,
commits offsets before leaving.

=head2 begin_transaction

Start a transaction. Requires C<transactional_id> in constructor.

=head2 send_offsets_to_transaction($group_id, [$cb])

Commit consumer offsets within the current transaction via
C<TxnOffsetCommit>. This is the key step for exactly-once
consume-process-produce pipelines.

    $kafka->send_offsets_to_transaction('my-group', sub {
        my ($result, $err) = @_;
    });

=head2 commit_transaction([$cb])

Commit the current transaction. All produced messages and offset
commits within the transaction become visible atomically.

=head2 abort_transaction([$cb])

Abort the current transaction. All produced messages are discarded
and offset commits are rolled back.

=head2 close([$cb])

Graceful shutdown: stop timers, disconnect all broker connections.

    $kafka->close(sub { EV::break });

=head1 LOW-LEVEL CONNECTION METHODS

C<EV::Kafka::Conn> provides direct access to a single broker connection.
Useful for custom protocols, debugging, or when cluster-level routing
is not needed.

    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    $conn->on_error(sub { warn @_ });
    $conn->on_connect(sub { ... });
    $conn->connect('127.0.0.1', 9092, 5.0);

=head2 connect($host, $port, [$timeout])

Connect to a broker. Timeout in seconds (0 = no timeout).

=head2 disconnect

Disconnect from broker.

=head2 connected

Returns true if the connection is ready (ApiVersions handshake complete).

=head2 metadata(\@topics, $cb)

Request cluster metadata. Pass C<undef> for all topics.

    $conn->metadata(['my-topic'], sub {
        my ($result, $err) = @_;
        # $result->{brokers}, $result->{topics}
    });

=head2 produce($topic, $partition, $key, $value, [\%opts,] [$cb])

Produce a message to a specific partition.

    $conn->produce('topic', 0, 'key', 'value', sub {
        my ($result, $err) = @_;
    });

Options: C<acks> (default 1), C<headers> (hashref), C<timestamp>
(epoch ms, default now), C<compression> (C<'none'>, C<'lz4'>; requires
LZ4 at build time).

=head2 produce_batch($topic, $partition, \@records, [\%opts,] [$cb])

Produce multiple records in a single RecordBatch. Each record is
C<{key, value, headers}>. Options: C<acks>, C<compression>,
C<producer_id>, C<producer_epoch>, C<base_sequence>.

    $conn->produce_batch('topic', 0, [
        { key => 'k1', value => 'v1' },
        { key => 'k2', value => 'v2' },
    ], sub { my ($result, $err) = @_ });

=head2 fetch($topic, $partition, $offset, $cb, [$max_bytes])

Fetch messages from a partition starting at C<$offset>.

    $conn->fetch('topic', 0, 0, sub {
        my ($result, $err) = @_;
        for my $rec (@{ $result->{topics}[0]{partitions}[0]{records} }) {
            printf "offset=%d key=%s value=%s\n",
                $rec->{offset}, $rec->{key}, $rec->{value};
        }
    });

=head2 fetch_multi(\%topics, $cb, [$max_bytes])

Multi-partition fetch in a single request. Groups multiple
topic-partitions into one Fetch call to the broker.

    $conn->fetch_multi({
        'topic-a' => [{ partition => 0, offset => 10 },
                       { partition => 1, offset => 20 }],
        'topic-b' => [{ partition => 0, offset => 0 }],
    }, sub { my ($result, $err) = @_ });

Used internally by C<poll()> to batch fetches by broker leader.

=head2 list_offsets($topic, $partition, $timestamp, $cb)

Get offsets by timestamp. Use C<-2> for earliest, C<-1> for latest.

=head2 find_coordinator($key, $cb, [$key_type])

Find the coordinator broker. C<$key_type>: 0=group (default),
1=transaction.

=head2 join_group($group_id, $member_id, \@topics, $cb, [$session_timeout_ms, $rebalance_timeout_ms, $group_instance_id])

Join a consumer group. Pass C<$group_instance_id> for KIP-345 static
membership.

=head2 sync_group($group_id, $generation_id, $member_id, \@assignments, $cb, [$group_instance_id])

Synchronize group state after join.

=head2 heartbeat($group_id, $generation_id, $member_id, $cb, [$group_instance_id])

Send heartbeat to group coordinator.

=head2 offset_commit($group_id, $generation_id, $member_id, \@offsets, $cb)

Commit consumer offsets.

=head2 offset_fetch($group_id, \@topics, $cb)

Fetch committed offsets for a consumer group.

=head2 api_versions

Returns a hashref of supported API keys to max versions, or undef
if not yet negotiated.

    my $vers = $conn->api_versions;
    # { 0 => 7, 1 => 11, 3 => 8, ... }

=head2 on_error([$cb])

=head2 on_connect([$cb])

=head2 on_disconnect([$cb])

Set handler callbacks. Pass C<undef> to clear.

=head2 client_id($id)

Set the client identifier.

=head2 tls($enable, [$ca_file, $skip_verify])

Configure TLS.

=head2 sasl($mechanism, [$username, $password])

Configure SASL authentication.

=head2 auto_reconnect($enable, [$delay_ms])

Enable automatic reconnection with delay in milliseconds (default 1000).

=head2 leave_group($group_id, $member_id, $cb)

Send LeaveGroup to coordinator for fast partition rebalance.

=head2 create_topics(\@topics, $timeout_ms, $cb)

Create topics. Each element: C<{name, num_partitions, replication_factor}>.

    $conn->create_topics(
        [{ name => 'new-topic', num_partitions => 3, replication_factor => 1 }],
        5000, sub { my ($res, $err) = @_ }
    );

=head2 delete_topics(\@topic_names, $timeout_ms, $cb)

Delete topics by name.

=head2 init_producer_id($transactional_id, $txn_timeout_ms, $cb)

Initialize a producer ID for idempotent/transactional produce.
Pass C<undef> for non-transactional idempotent producer.

=head2 add_partitions_to_txn($txn_id, $producer_id, $epoch, \@topics, $cb)

Register partitions with the transaction coordinator.

=head2 end_txn($txn_id, $producer_id, $epoch, $committed, $cb)

Commit (C<$committed=1>) or abort (C<$committed=0>) a transaction.

=head2 txn_offset_commit($txn_id, $group_id, $producer_id, $epoch, $generation, $member_id, \@offsets, $cb)

Commit consumer offsets within a transaction (API 28).

=head2 pending

Number of requests awaiting broker response.

=head2 state

Connection state as integer (0=disconnected, 6=ready).

=head1 UTILITY FUNCTIONS

=head2 EV::Kafka::_murmur2($key)

Kafka-compatible murmur2 hash. Returns a non-negative 31-bit integer.

=head2 EV::Kafka::_crc32c($data)

CRC32C checksum (Castagnoli). Used internally for RecordBatch integrity.

=head2 EV::Kafka::_error_name($code)

Convert Kafka error code to string name.

=head1 RESULT STRUCTURES

=head2 Produce result

    $result = {
        topics => [{
            topic      => 'name',
            partitions => [{
                partition   => 0,
                error_code  => 0,
                base_offset => 42,
            }],
        }],
    };

=head2 Fetch result

    $result = {
        topics => [{
            topic      => 'name',
            partitions => [{
                partition      => 0,
                error_code     => 0,
                high_watermark => 100,
                records => [{
                    offset    => 42,
                    timestamp => 1712345678000,
                    key       => 'key',      # or undef
                    value     => 'value',     # or undef
                    headers   => { h => 'v' },  # if present
                }],
            }],
        }],
    };

=head2 Metadata result

    $result = {
        controller_id => 0,
        brokers => [{ node_id => 0, host => '10.0.0.1', port => 9092 }],
        topics  => [{
            name       => 'topic',
            error_code => 0,
            partitions => [{
                partition  => 0,
                leader     => 0,
                error_code => 0,
            }],
        }],
    };

=head1 ERROR HANDLING

Errors are delivered through two channels:

=over

=item B<Connection-level errors> fire the C<on_error> callback (or
C<croak> if none set). These include connection refused, DNS failure,
TLS errors, SASL auth failure, and protocol violations.

=item B<Request-level errors> are delivered as the second argument to
the request callback: C<$cb-E<gt>($result, $error)>. If C<$error> is
defined, C<$result> may be undef.

=back

Within result structures, per-partition C<error_code> fields use Kafka
numeric codes:

    0   No error
    1   OFFSET_OUT_OF_RANGE
    3   UNKNOWN_TOPIC_OR_PARTITION
    6   NOT_LEADER_OR_FOLLOWER
    15  COORDINATOR_NOT_AVAILABLE
    16  NOT_COORDINATOR
    25  UNKNOWN_MEMBER_ID
    27  REBALANCE_IN_PROGRESS
    36  TOPIC_ALREADY_EXISTS
    79  MEMBER_ID_REQUIRED

When a broker disconnects mid-flight, all pending callbacks receive
C<(undef, "connection closed by broker")> or C<(undef, "disconnected")>.

=head1 ENVIRONMENT VARIABLES

These are used by tests and examples (not by the module itself):

    TEST_KAFKA_BROKER    broker address for tests (host:port)
    KAFKA_BROKER         broker address for examples
    KAFKA_HOST           broker hostname for low-level examples
    KAFKA_PORT           broker port for low-level examples
    KAFKA_TOPIC          topic name for examples
    KAFKA_GROUP_ID       consumer group for examples
    KAFKA_LIMIT          message limit for consume example
    KAFKA_COUNT          message count for fire-and-forget
    BENCH_BROKER         broker for benchmarks
    BENCH_MESSAGES       message count for benchmarks
    BENCH_VALUE_SIZE     value size in bytes for benchmarks
    BENCH_TOPIC          topic name for benchmarks

=head1 QUICK START

Minimal producer + consumer lifecycle:

    use EV;
    use EV::Kafka;

    my $kafka = EV::Kafka->new(
        brokers    => '127.0.0.1:9092',
        acks       => 1,
        on_error   => sub { warn "kafka: @_\n" },
        on_message => sub {
            my ($topic, $part, $offset, $key, $value) = @_;
            print "got: $key=$value\n";
        },
    );

    $kafka->connect(sub {
        # produce
        $kafka->produce('test', 'k1', 'hello', sub {
            print "produced\n";

            # consume from the beginning
            $kafka->assign([{topic=>'test', partition=>0, offset=>0}]);
            $kafka->seek('test', 0, -2, sub {
                my $t = EV::timer 0, 0.1, sub { $kafka->poll };
                $kafka->{cfg}{_t} = $t;
            });
        });
    });

    EV::run;

=head1 COOKBOOK

=head2 Produce JSON with headers

    use JSON::PP;
    my $json = JSON::PP->new->utf8;

    $kafka->produce('events', 'user-42',
        $json->encode({ action => 'click', page => '/home' }),
        { headers => { 'content-type' => 'application/json' } },
        sub { ... }
    );

=head2 Consume from latest offset only

    $kafka->subscribe('live-feed',
        group_id          => 'realtime',
        auto_offset_reset => 'latest',
        on_assign         => sub { print "ready\n" },
    );

=head2 Graceful shutdown

    $SIG{INT} = sub {
        $kafka->commit(sub {
            $kafka->unsubscribe(sub {
                $kafka->close(sub { EV::break });
            });
        });
    };

=head2 At-least-once processing

    $kafka->subscribe('jobs',
        group_id    => 'workers',
        auto_commit => 0,
    );

    # in on_message: process, then commit
    on_message => sub {
        process($_[4]);
        $kafka->commit if ++$count % 100 == 0;
    },

=head2 Batch produce

    $kafka->produce_many([
        ['events', 'k1', 'v1'],
        ['events', 'k2', 'v2'],
        ['events', 'k3', 'v3'],
    ], sub {
        my $errs = shift;
        print $errs ? "some failed\n" : "all done\n";
    });

=head2 Exactly-once stream processing (EOS)

    my $kafka = EV::Kafka->new(
        brokers          => '...',
        transactional_id => 'my-eos-app',
        acks             => -1,
        on_message => sub {
            my ($t, $p, $off, $key, $value) = @_;
            my $result = process($value);
            $kafka->produce('output-topic', $key, $result);
        },
    );

    # consume-process-produce loop:
    $kafka->begin_transaction;
    $kafka->poll(sub {
        $kafka->send_offsets_to_transaction('my-group', sub {
            $kafka->commit_transaction(sub {
                $kafka->begin_transaction;  # next transaction
            });
        });
    });

=head2 Topic administration

    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    $conn->on_connect(sub {
        $conn->create_topics(
            [{ name => 'new-topic', num_partitions => 6, replication_factor => 3 }],
            10000, sub { ... }
        );
    });

=head1 BENCHMARKS

Measured on Linux with TCP loopback to Redpanda, 100-byte values,
Perl 5.40.2, 50K messages (C<bench/benchmark.pl>):

    Pipeline produce (acks=1)    68K msg/sec     7.4 MB/s
    Fire-and-forget (acks=0)    100K msg/sec    11.0 MB/s
    Fetch throughput             31K msg/sec     3.4 MB/s
    Sequential round-trip        19K msg/sec    54 us avg latency
    Metadata request             25K req/sec    41 us avg latency

Throughput by value size (pipelined, acks=1):

       10 bytes    61K msg/sec      0.9 MB/s
      100 bytes    68K msg/sec      7.4 MB/s
     1000 bytes    50K msg/sec     50.2 MB/s
    10000 bytes    18K msg/sec    178.5 MB/s

Pipeline produce throughput is limited by Perl callback overhead per
message. Fire-and-forget mode (C<acks=0>) skips the response cycle
entirely, reaching ~100K msg/sec. Sequential round-trip (one produce,
wait for ack, repeat) measures raw broker latency at ~54 microseconds.

The fetch path is sequential (fetch, process, fetch again) which
introduces one round-trip per batch. With larger C<max_bytes> and
dense topics, fetch throughput increases proportionally.

Run C<perl bench/benchmark.pl> for throughput results. Set
C<BENCH_BROKER>, C<BENCH_MESSAGES>, C<BENCH_VALUE_SIZE>, and
C<BENCH_TOPIC> to customize.

Run C<perl bench/latency.pl> for a latency histogram with percentiles
(min, avg, median, p90, p95, p99, max).

=head1 KAFKA PROTOCOL

This module implements the Kafka binary protocol directly in XS.
All integers are big-endian. Requests use a 4-byte size prefix
followed by a header (API key, version, correlation ID, client ID)
and a version-specific body.

Responses are matched to requests by correlation ID. The broker
guarantees FIFO ordering per connection, so the response queue is
a simple FIFO.

RecordBatch encoding (magic=2) is used for produce. CRC32C covers
the batch from attributes through the last record. Records use
ZigZag-encoded varints for lengths and deltas.

The connection handshake sends ApiVersions (v0) on connect to
discover supported protocol versions. SASL authentication uses
SaslHandshake (v1) + SaslAuthenticate (v2) with PLAIN mechanism.

Consumer group protocol uses sticky partition assignment with
MEMBER_ID_REQUIRED (error 79) retry per KIP-394.

Non-flexible API versions are used throughout (capped below the
flexible-version threshold for each API) to avoid the compact
encoding complexity.

=head1 LIMITATIONS

=over

=item * B<LZ4 and gzip compression> -- supported when built with
liblz4 and zlib. snappy and zstd are not implemented.

=item * B<Transactions / EOS> -- C<begin_transaction>,
C<send_offsets_to_transaction>, C<commit_transaction>,
C<abort_transaction> provide full exactly-once stream processing.
C<InitProducerId>, C<AddPartitionsToTxn>, C<TxnOffsetCommit>, C<EndTxn>
are all wired. Requires C<transactional_id> in constructor.

=item * B<No GSSAPI/OAUTHBEARER> -- SASL/PLAIN and SCRAM-SHA-256/512
are supported. GSSAPI (Kerberos) and OAUTHBEARER are not implemented.

=item * B<Sticky partition assignment> -- assignments are preserved
across rebalances where possible. New partitions are distributed to
the least-loaded member. Overloaded members shed excess partitions.

=item * B<Blocking DNS resolution> -- C<getaddrinfo> is called
synchronously in C<conn_start_connect>. For fully non-blocking
operation, use IP addresses instead of hostnames.

=item * B<No flexible API versions> -- all API versions are capped
below the flexible-version threshold to avoid compact string/array
encoding. This limits interoperability with very new protocol features
but works with all Kafka 0.11+ and Redpanda brokers.

=item * B<Limited produce retry> -- transient errors (NOT_LEADER,
COORDINATOR_NOT_AVAILABLE) trigger metadata refresh and up to 3
retries with backoff. Non-retriable errors are surfaced to the
callback immediately.

=back

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


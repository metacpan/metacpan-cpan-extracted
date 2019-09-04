
package Forks::Queue::File;
use strict;
use warnings;
use Carp;
use JSON;
use Time::HiRes;
use base 'Forks::Queue';
use 5.010;    #  sorry, v5.08. I love the // //=  operators too much

our $VERSION = '0.12';
our $DEBUG;
*DEBUG = \$Forks::Queue::DEBUG;

$SIG{IO} = sub { } if $Forks::Queue::NOTIFY_OK;


# prefer functional JSON calls because we still want to use JSON
# during global destruction, and a JSON object might not be available
# then
sub jsonize {
    JSON::to_json($_[0], { allow_nonref=>1, ascii=>1 } );
}

sub dejsonize {
    JSON::from_json($_[0], { allow_nonref => 1, ascii => 1 } );
}

# if we exercise firm control over line endings,
# we won't have any DOS vs Unix vs Mac fights.
use constant EOL => "\x{0a}";
# Anything that can't be a valid JSON substring is ok to use here

sub _SYNC (&$) {
    my ($block,$self) = @_;
    return if Forks::Queue::__inGD();

    my $lock;
    local $! = 0;
    if ($self->{_locked}) {
        Carp::cluck "$$ acquiring lock but already have lock";
    }
    open $lock, '>>', $self->{lock};
    my $z = flock $lock, 2;
    while (!$z && $Forks::Queue::NOTIFY_OK && $!{EINTR}) {
        # SIGIO can interrupt flock
        $z = flock $lock, 2;
    }
    $self->{_locked} = 1;

    $DEBUG and print STDERR "$$ Locked $self->{lock} z=$z\n";

    my $result = $block->($self);

    $self->{_locked} = 0;
    close $lock;
    $DEBUG and print STDERR "$$ Unlocked\n";
    return $result;
}

sub _SYNCWA (&$) {    # wantarray version of _SYNC
    my ($block,$self) = @_;

    if ($self->{_locked}) {
        Carp::cluck "$$ acquiring lock but already have lock";
    }
    open my $lock, '>>', $self->{lock};
    my $z = flock $lock, 2;
    $self->{_locked} = 1;

    $DEBUG and print STDERR "$$ Locked $self->{lock} z=$z\n";

    my @result = $block->($self);

    $self->{_locked} = 0;
    close $lock;
    $DEBUG and print STDERR "$$ Unlocked\n";
    return @result;
}

sub _PID {
    $INC{'threads.pm'} ? join("-", $$, threads->tid) : $$
}

sub new {
    my $class = shift;
    my %opts = (%Forks::Queue::OPTS, @_);

    $opts{file} //= _impute_file();
    $opts{lock} = $opts{file} . ".lock";
    my $list = delete $opts{list};

    my $fh;

    $opts{_header_size} //= 2048;
    $opts{_end} = 0;            # whether "end" has been called for this obj
    $opts{_pos} = 0;		# "cursor", index of next item to shift out
    $opts{_tell} = $opts{_header_size};        # file position of cursor

    $opts{_count} = 0;          # index of next item to be appended
    $opts{_pids} = { _PID() => 'P' };
    $opts{_version} = $Forks::Queue::VERSION;

    # how often to refactor the queue file. use small values to keep file
    # sizes small and large values to improve performance
    $opts{_maintenance_freq} //= 128;

    open $fh, '>>', $opts{lock} or die;
    close $fh or die;

    my $self = bless { %opts }, $class;

    if ($opts{join} && -f $opts{file}) {
        $DB::single = 1;
        open $fh, '+<', $opts{file} or die;
        $self->{_fh} = *$fh;
        my $fhx = select $fh; $| = 1; select $fhx;
        _SYNC { $self->_read_header } $self;
    } else {
        if (-f $opts{file}) {
            carp "Forks::Queue: Queue file $opts{file} already exists. ",
                 "Expect trouble if another process created this file.";
        }
        open $fh, '>', $opts{file} or die;
        close $fh or die;

        open $fh, '+<', $opts{file} or die;
        my $fhx = select $fh; $| = 1; select $fhx;
        $self->{_fh} = *$fh;
        seek $fh, 0, 0;

        $self->{_locked}++;
        $self->_write_header;
        $self->{_locked}--;
        if (tell($fh) < $self->{_header_size}) {
            print $fh "\0" x ($self->{_header_size} - tell($fh));
        }
    }
    if (defined($list)) {
        if (ref($list) eq 'ARRAY') {
            $self->push( @$list );
        } else {
            carp "Forks::Queue::new: 'list' option must be an array ref";
        }
    }

    return $self;
}


sub DESTROY {
    my $self = shift;
    $self->{_DESTROY}++;
    eval {
    _SYNC {
        if ($self->_read_header) {
            $DEBUG and print STDERR "$$ DESTROY: pids at destruction: ",
                                join(" ",keys %{$self->{_pids}}),"\n";
            delete $self->{_pids}{_PID()};
            $self->_write_header;
        } else {
            $DEBUG and print STDERR "$$ DESTROY: header not available\n";
        }
    } $self;
    };
    if ($@) {
        if ($@ !~ /malformed JSON ...* at character offset 0/) {
            use Data::Dumper;
            print STDERR Dumper($@,$self);
        }
    }
    $self->{_fh} && close $self->{_fh};
    $DEBUG and print STDERR "$$ DESTROY: remaining pids: ",
                                join(" ",keys %{$self->{_pids}}),"\n";
    if ($self->{_pids} && 0 == keys %{$self->{_pids}}) {
        $DEBUG and print STDERR "$$ Unlinking files from here\n";
        unlink $self->{lock};
        unlink $self->{file} unless $self->{persist};
        $DEBUG and print STDERR
            "$$ DESTROY: unlink time " . Time::HiRes::time . "\n";
    }
}

# the key to a shared file acting as a queue is the header,
# which holds the queue metadata like the file position of
# the current front and back of the queue, and the identifiers
# of processes that are using the queue.
#
# this function should only be called from inside a _SYNC block.

sub _read_header {
    my ($self) = @_;
    Carp::cluck "unsafe _read_header" unless $self->{_locked};
    local $/ = EOL;
    my $h = "";
    if ($self->{_DESTROY}) {
        no warnings 'closed';
        seek $self->{_fh}, 0, 0;
        $h = readline($self->{_fh}) // "";
    } else {
        local $! = 0;
        if (seek $self->{_fh}, 0, 0) {
            $h = readline($self->{_fh});
        } else {
            Carp::cluck "_read_header: invalid seek $!";
            return;
        }
    }
    if (!$h) {
        if ($self->{_DESTROY}) {
            return;
        }
        Carp::cluck "_read_header: header not found";
    }
    chomp($h);
    $h = dejsonize($h);
    $self->{_pos} = $h->{index};
    $self->{_end} = $h->{end};
    $self->{_tell} = $h->{tell};
    $self->{_count} = $h->{count};
    $self->{_header_size} = $h->{headerSize};
    $self->{_maintenance_freq} = $h->{maintFreq};
    $self->{_version} = $h->{version};
    $self->{_pids} = $h->{pids};
    $self->{limit} = $h->{limit} if $h->{limit};

    $DEBUG && print STDERR "$$ read header\n";

    $h->{avail} = $self->{_avail} = $h->{count} - $h->{index};  # not written
    return $h;
}

sub _write_header {
    my ($self) = @_;
    Carp::cluck "unsafe _write_header" unless $self->{_locked};
    my $header = { index => $self->{_pos}, end => $self->{_end},
                   tell => $self->{_tell}, count => $self->{_count},
                   limit => $self->{limit},
                   pids => $self->{_pids},
                   headerSize => $self->{_header_size},
                   maintFreq => $self->{_maintenance_freq},
                   version => $self->{_version}  };

    my $headerstr = jsonize($header);
    while (length($headerstr) >= $self->{_header_size}) {
        $self->_increase_header_size(length($headerstr) + 32);
        $header->{tell} = $self->{_tell};
        $headerstr = jsonize($header);
    }

    eval {
        no warnings;
        seek $self->{_fh}, 0, 0;
        print {$self->{_fh}} $headerstr,EOL;
        $DEBUG && print STDERR "$$ updated header $headerstr\n";
    };
}

sub _notify {
    return unless $Forks::Queue::NOTIFY_OK;

    my $self = shift;
    _SYNC { $self->_read_header } $self;
    my @ids = keys %{$self->{_pids}};
    my (@pids,@tids);
    my $me = _PID();
    $DEBUG && print STDERR "_notify \$me=$me  \@ids=@ids\n";
    foreach my $id (@ids) {
        my ($p,$t) = split /-/,$id;
        if (!$p) {
            ($p,$t) = (-$t,0);
        }
        if ($p != $$) {
            push @pids, $p;
        } elsif (defined($t) && $id ne $me) {
            push @tids, $t;
        }
    }
    if (@tids) {
        $DEBUG && print STDERR "$$ notify: tid @tids\n";
        foreach my $tid (@tids) {
            my $thr = threads->object($tid);
            if ($thr) {
                my $z7;
                $thr && ($z7 = $thr->kill('IO')) &&
                    $DEBUG && print STDERR "_notify to tid $$-$tid \$z7=$z7\n";
                if ($tid ne $tids[-1]) {
                    #Time::HiRes::sleep 0.25;
                }

                # $thr->kill is not reliable?
                
            } elsif ($tid == 0) {
                $DEBUG && print STDERR "_notify SIGIO to tid main\n";
                kill 'IO', $$;
            } else {
                $DEBUG && print STDERR "_notify failed to SIGIO tid $tid\n";
            }
        }
    }
    if (@pids) {
        $DEBUG && print STDERR "_notify to pids @pids\n";
        kill 'IO', @pids;
    }
}

sub clear {
    my $self = shift;
    if (! eval { $self->_check_pid; 1 } ) {
        carp("File::Queue::clear operation failed: $@");
        return;
    }
    _SYNC {
        $self->_read_header;
        $self->{_pos} = 0;
        $self->{_tell} = $self->{_header_size};
        $self->{_count} = 0;
        truncate $self->{_fh}, $self->{_tell};
        $self->_write_header;
    } $self;
}

sub end {
    my ($self) = @_;
    if (! eval { $self->_check_pid; 1 } ) {
        carp "Forks::Queue::end operation failed: $@";
        return;
    }
    _SYNC {
        $self->_read_header;
        if ($self->{_end}) {
            carp "Forks::Queue: end() called from $$, ",
                 "previously called from $self->{_end}";
        } else {
            $self->{_end} = _PID();
        }
        $self->_write_header;
    } $self;
    $self->_notify;
    return;
}

sub status {
    my ($self) = @_;
    my $status = _SYNC { $self->_read_header } $self;
    $status->{file} = $self->{file};
    $status->{filesize} = -s $self->{_fh};
    $status->{end} = $self->{_end};
    return $status;
}

sub _check_pid {
    my ($self) = @_;
    if (!defined $self->{_pids}{_PID()}) {
        if ($Forks::Queue::NOTIFY_OK) {
            if (_PID() =~ /.-[1-9]/) {
                # SIGIO can't be reliably passed to threads, so can't
                # rely on long sleep command being interrupted
                $Forks::Queue::SLEEP_INTERVAL = 1;
            }
            $SIG{IO} = sub { };
        }
        my $ostatus = open $self->{_fh}, '+<', $self->{file};
        for (1..5) {
            last if $ostatus;
            sleep 1;
            $ostatus = open $self->{_fh}, '+<', $self->{file};            
        }
        if (!$ostatus) {
            Carp::confess("Forks::Queue::check_pid: ",
                          "Could not open $self->{file} after 5 tries");
            return;
        }
        if ($self->{_locked}) {
            $DEBUG && print STDERR
                "Forks::Queue: $$ new pid update header\n";
            $self->{_pids}{_PID()} = 'C';
            $self->_write_header;
            return;
        } else {
            $DEBUG and print STDERR "Forks::Queue: $$ new pid sync\n";
            _SYNC {
                $self->_read_header;
                $self->{_pids}{_PID()} = 'C';
                $self->_write_header;
            } $self;
            return;
        }
    }
    return;
}

sub _increase_header_size {
    my ($self,$min_size) = @_;
    # assumes $self has been updated by $self->_read_header recently
    return if $min_size <= $self->{_header_size};

    local $/ = EOL;
    my $delta = $min_size - $self->{_header_size};
    seek $self->{_fh}, $self->{_header_size}, 0;
    my @data = readline($self->{_fh});
    seek $self->{_fh}, 0, 0;
    print {$self->{_fh}} "\0" x $min_size;
    print {$self->{_fh}} @data;
    $self->{_header_size} = $min_size;
    $self->{_tell} += $delta;
    return;
}

sub _maintain {
    my ($self) = @_;
    # assumes $self has been updated by $self->_read_header recently

    my $delta = $self->{_tell} - $self->{_header_size};
    return if $delta == 0;
    local $/ = EOL;
    seek $self->{_fh}, $self->{_tell}, 0;
    my @data = readline($self->{_fh});
    seek $self->{_fh}, $self->{_header_size}, 0;
    print {$self->{_fh}} @data;
    truncate $self->{_fh}, tell($self->{_fh});

    $self->{_avail} = $self->{_count} = @data;
    $self->{_pos} = 0;
    $self->{_tell} = $self->{_header_size};
    return;
}

sub push {
    my ($self,@items) = @_;
    if (! eval { $self->_check_pid; 1 } ) {
        carp "Forks::Queue::put call from process $$ failed: $@";
        return;
    }

    my (@deferred_items,$failed_items);
    my $pushed = 0;
    _SYNC {
        $self->_read_header;
        if ($self->{_end}) {
            carp "Forks::Queue: put call from process $$ ",
                 "after end call from process ", $self->{_end}, "!";
            return 0;
        }

        # TODO: check if queue  limit  is reached, consult  on_limit
        if ($self->{limit} > 0) {
            $failed_items = $self->{_avail} + @items - $self->{limit};
            if ($failed_items > 0) {
                @deferred_items = splice @items, -$failed_items;
                if (@items == 0) {
                    return;
                }
            } else {
                $failed_items = 0;
            }
        }

        seek $self->{_fh}, 0, 2;
        if (tell($self->{_fh}) < $self->{_tell}) {
            Carp::cluck "funny seek";
            seek $self->{_fh}, $self->{_tell}, 0;
        }
        foreach my $item (@items) {
            my $json = jsonize($item);
            print {$self->{_fh}} $json,EOL;
            $self->{_count}++;
            $self->{_avail}++;
            $pushed++;
            $DEBUG && print STDERR
                "$$ put item [$json] $pushed/",0+@items,"\n";
        }
        $self->_write_header;
    } $self;
    if ($pushed && $DEBUG) {
        print STDERR "_notify from push(\$pushed=$pushed)\n";
    }
    $self->_notify if $pushed;

    if ($failed_items) {
        if ($self->{on_limit} eq 'fail') {
            carp "Forks::Queue: queue buffer is full ",
                 "and $failed_items items were not added";
        } else {
            $DEBUG && print STDERR
                "$$ $failed_items on put. Waiting for capacity\n";
            $self->_wait_for_capacity;
            $DEBUG && print STDERR "$$ got some capacity\n";
            $pushed += $self->push(@deferred_items);        }
    }
    return $pushed;
}

sub unshift {
    my ($self,@items) = @_;
    return $self->insert(0, @items);
}

sub _SLEEP {
    my $self = shift;
    # my $tid = threads->self;
    my $n = sleep($Forks::Queue::SLEEP_INTERVAL || 1);
    #Carp::cluck("LONG SLEEP \$n=$n") if $n > 10;
    return $n;
}

sub _wait_for_item {
    my ($self) = @_;
    my $ready = 0;
    do {
        _SYNC { $self->_read_header } $self;
        $ready = $self->{_avail} || $self->{_end} || $self->_expired;
        if (!$ready) {
            _SLEEP($self); #sleep($Forks::Queue::SLEEP_INTERVAL||1)
        }
    } while !$ready;
    return $self->{_avail};
}

sub _wait_for_capacity {
    my ($self) = @_;
    my $ready = 0;
    do {
        if ($self->{limit} <= 0) {
            $ready = 1;
        } else {
            _SYNC { $self->_read_header } $self;
            $ready = $self->{_avail} < $self->{limit} && !$self->{_end};
            if (!$ready) {
                _SLEEP($self); #sleep($Forks::Queue::SLEEP_INTERVAL || 1) if !$ready;
            }
        }
    } while !$ready;
    return $self->{_avail} < $self->{limit};
}

sub dequeue {
    my $self = shift;
    Forks::Queue::_validate_input($_[0],'count',1) if @_;
    if ($self->{style} ne 'lifo') {
        return @_ ? $self->_dequeue_front(@_) : $self->_dequeue_front;
    } else {
        return @_ ? $self->_dequeue_back(@_) : $self->_dequeue_back;
    }
}

sub _dequeue_back {
    my $self = shift;
    my $count = @_ ? $_[0] // 1 : 1;
    if (! eval { $self->_check_pid; 1 } ) {
        carp "Forks::Queue::pop operation failed: $@";
        return;
    }
    my @return;
    local $/ = EOL;
    while (@return == 0) {
        _SYNC {
            return if $self->{_avail} < $count && !$self->{_end};
            seek $self->{_fh}, $self->{_tell}, 0;
            my $avail = $self->{_avail};
            while ($avail > $count) {
                scalar readline($self->{_fh});
                $avail--;
            }
            my $spot = tell $self->{_fh};
            @return = map dejsonize($_), readline($self->{_fh});
            truncate $self->{_fh}, $spot;
            $self->{_count} -= @return;
            $self->_write_header;
        } $self;
        last if @return || $self->{_end} || $self->_expired;
        _SLEEP($self); #sleep($Forks::Queue::SLEEP_INTERVAL || 1);
    }
    $self->_notify if @return;
    if ($self->_expired && @return == 0) {
        return @_ ? $self->pop_nb(@_) : $self->pop_nb;
    }
    return @_ ? @return : $return[0] // ();
}

sub _dequeue_front {
    my $self = shift;
    my $count = @_ ? $_[0] // 1 : 1;
    if (! eval { $self->_check_pid; 1 } ) {
        carp "Forks::Queue::shift operation failed: $@";
        return;
    }
    my @return;
    local $/ = EOL;
    while (@return == 0) {
        _SYNC {
            $self->_read_header;
            return if $self->{_avail} < $count && !$self->{_end};
            seek $self->{_fh}, $self->{_tell}, 0;
            while (@return < $count && $self->{_avail} > 0) {
                my $item = readline($self->{_fh});
                if (!defined($item)) {
                    $self->_write_header;
                    return;
                }
                chomp($item);
                eval {
                    CORE::push @return, dejsonize($item);
                };
                if ($@) {
                    $self->_write_header;
                    die "JSON was \"$item\", error was $@";
                }
                $self->{_pos}++;
                $self->{_tell} = tell $self->{_fh};
                $self->{_avail}--;
            }
            if ($self->{_maintenance_freq} &&
                $self->{_pos} >= $self->{_maintenance_freq}) {

                $self->_maintain;
            }
            $self->_write_header;
        } $self;
        last if @return || $self->{_end} || $self->_expired;
        _SLEEP($self); #sleep($Forks::Queue::SLEEP_INTERVAL || 1);
    }
    $self->_notify if @return;
    if ($self->_expired && @return == 0) {
        return @_ ? $self->shift_nb(@_) : $self->shift_nb;
    }
    return @_ ? @return : $return[0] // ();
}

sub shift :method {
    my ($self,$count) = @_;
    $count ||= 1;
    if (! eval { $self->_check_pid; 1 } ) {
        carp "Forks::Queue::shift method failed: $@";
        return;
    }

    my @return;
    while (@return == 0) {
        my $h;
        return if !$self->_wait_for_item;
	local $/ = EOL;
        _SYNC {
            $self->_read_header;

            seek $self->{_fh}, $self->{_tell}, 0;
            while (@return < $count && $self->{_avail} > 0) {
                my $item = readline($self->{_fh});
                if (defined($item)) {
                    chomp($item);
                    eval {
                        CORE::push @return, dejsonize($item);
                    };
                    if ($@) {
                        $self->_write_header;
                        die "JSON was \"$item\", error was $@";
                    }
                    $self->{_pos}++;
                    $self->{_tell} = tell $self->{_fh};
                    $self->{_avail}--;
                }
            }
            if ($self->{_maintenance_freq} &&
                $self->{_pos} >= $self->{_maintenance_freq}) {

                $self->_maintain;
            }
            $self->_write_header;
        } $self;
    }
    $self->_notify if @return;
    if (!wantarray && @_ < 2) {
        return $return[0] // ();
    } else {
        return @return;
    }
}

sub shift_nb {
    my ($self,$count) = @_;
    $count ||= 1;
    if (! eval { $self->_check_pid; 1 } ) {
        carp "Forks::Queue::shift operation failed: $@";
        return;
    }

    my @return;
    my $h;
    #return if !$self->_wait_for_item;
    local $/ = EOL;
    _SYNC {
        $self->_read_header;

        seek $self->{_fh}, $self->{_tell}, 0;
        while (@return < $count && $self->{_avail} > 0) {
            my $item = readline($self->{_fh});
            if (!defined($item)) {
                $self->_write_header;
                return;
            }
            chomp($item);
            eval {
                CORE::push @return, dejsonize($item);
            };
            if ($@) {
                die "JSON was \"$item\", error was $@";
            }
            $self->{_pos}++;
            $self->{_tell} = tell $self->{_fh};
            $self->{_avail}--;
        }
        if ($self->{_maintenance_freq} &&
            $self->{_pos} >= $self->{_maintenance_freq}) {

            $self->_maintain;
        }
        $self->_write_header;
        return;
    } $self;
    $self->_notify if @return;
    if (!wantarray && @_ < 2) {
        return $return[0] // ();
    } else {
        return @return;
    }
}

sub peek_front {
    my ($self, $index) = @_;
    $index ||= 0;
    if ($index < 0) {
        return $self->peek_back(-$index - 1);
    }
    if (! eval { $self->_check_pid; 1 } ) {
        carp "Forks::Queue::peek operation failed: $@";
        return;
    }
    my @return;
    local $/ = EOL;

    my $h;
    _SYNC { $self->_read_header } $self;
    return if $self->{_avail} <= $index;

    _SYNC {
        $self->_read_header;

        seek $self->{_fh}, $self->{_tell}, 0;
        my $item;
        while ($index-- >= 0) {
            $item = readline($self->{_fh});
            if (!defined($item)) {
                return;
            }
        }
        chomp($item);

        CORE::push @return, dejsonize($item);
    } $self;
    return $return[0];
}

sub peek_back {
    my ($self, $index) = @_;
    $index ||= 0;
    if ($index < 0) {
        return $self->peek_front(-$index - 1);
    }
    if (! eval { $self->_check_pid; 1 } ) {
        carp "Forks::Queue::peek operation failed: $@";
        return;
    }
    my $count = $index + 1;
    local $/ = EOL;
    my @return;

    my $h;
    _SYNC {
        $self->_read_header;
        return if $self->{_avail} <= $index;

        seek $self->{_fh}, $self->{_tell}, 0;
        my $pos = $self->{_pos};
        while ($pos + $count < $self->{_count}) {
            scalar readline($self->{_fh});
            $pos++;
        }
        my $item = readline($self->{_fh});
        chomp($item);
        @return = dejsonize($item);
    } $self;
    return $return[0];
}

sub extract {
    my $self = shift;
    Forks::Queue::_validate_input( $_[0], 'index' ) if @_;
    my $index = shift || 0;
    Forks::Queue::_validate_input( $_[0], 'count', 1) if @_;
    
    my $count = $_[0] // 1;
#   my $count = @_ ? shift : 1;
    if ($self->{style} eq 'lifo') {
        $index = -1 - $index;
        $index -= $count - 1;
    }
    local $/ = EOL;
    my @return;
    _SYNCWA {
        $self->_read_header;
        my $n = $self->{_avail};
        if ($count <= 0) {
            carp "Forks::Queue::extract: count must be positive";
            return;
        }
        if ($index < 0) {
            $index = $index + $n;
            if ($index < 0) {
                $count += $index;
                $index = 0;
            }
        }
        if ($count <= 0 || $index >= $n) {
            return;
        }
        if ($index + $count >= $n) {
            $count = $n - $index;
        }

        seek $self->{_fh}, $self->{_tell}, 0;
        scalar readline($self->{_fh}) for 0..$index-1;  # skip
        my $save = tell $self->{_fh};
        @return = map {
            my $item = readline($self->{_fh});
            chomp($item);
            $self->{_avail}--;
            $self->{_count}--;
            dejsonize($item);
        } 1..$count;
        my @buffer = readline($self->{_fh});
        seek $self->{_fh}, $save, 0;
        print {$self->{_fh}} @buffer;
        truncate $self->{_fh}, tell $self->{_fh};
        $self->_write_header;
    } $self;
    $self->_notify if @return;
    return @_ ? @return : $return[0] // ();
}

sub insert {
    my ($self, $pos, @items) = @_;
    Forks::Queue::_validate_input( $pos, 'index' );
    if (! eval { $self->_check_pid; 1 } ) {
        carp "Forks::Queue::insert operation failed: $@";
        return;
    }
    local $/ = EOL;
    my $nitems = @items;
    my (@deferred_items, $failed_items);
    my $inserted = 0;
    _SYNC {
        $self->_read_header;
        if ($self->{_end}) {
            carp "Forks::Queue::insert call from process $$ ",
                 "after end call from process ", $self->{_end}, "!";
            return 0;
        }
        if ($self->{limit} > 0) {
            my $failed_items = $self->{_avail} + @items - $self->{limit};
            if ($failed_items > 0) {
                @deferred_items = splice @items, -$failed_items;
                if (@items == 0) {
                    return;
                }
            } else {
                $failed_items = 0;
            }
        }

        if ($pos < 0) {
            $pos += $self->{_avail};
        }
        if ($pos >= $self->{_avail}) {
            # insert at end of queue (append)
            seek $self->{_fh}, 0, 2;
            if (tell($self->{_fh}) < $self->{_tell}) {
                Carp::cluck("funny seek");
                 seek $self->{_fh}, $self->{_tell}, 0;
            }
            foreach my $item (@items) {
                print {$self->{_fh}} jsonize($item),EOL;
                $self->{_count}++;
                $self->{_avail}++;
                $inserted++;
                $DEBUG && print STDERR
                    "$$ insert item $inserted/",0+@items,"\n";
            }
            $self->_write_header;
            return;
        }
        if ($pos < 0) {
            $pos = 0;
        }
        seek $self->{_fh}, $self->{_tell}, 0;
        while ($pos > 0) {
            scalar readline($self->{_fh});
            $pos--;
        }
        my $save = tell($self->{_fh});
        my @buffer = readline($self->{_fh});
        seek $self->{_fh}, $save, 0;
        foreach my $item (@items) {
            print {$self->{_fh}} jsonize($item),EOL;
            $self->{_count}++;
            $self->{_avail}++;
            $inserted++;
            $DEBUG && print STDERR
                "$$ insert item $inserted/",0+@items,"\n";
        }
        print {$self->{_fh}} @buffer;
        $self->_write_header;             
    } $self;
    if ($failed_items) {
        if ($self->{on_limit} eq 'fail') {
            carp "Forks::Queue: queue buffer is full ",
                 "and $failed_items items were not inserted";
        } else {
            $DEBUG && print STDERR
                "$$ $failed_items on insert. Waiting for capacity\n";
            $self->_wait_for_capacity;
            $DEBUG && print STDERR "$$ got some capacity\n";
            $inserted += $self->insert($pos+$inserted, @deferred_items);
        }
    }
    $self->_notify if $inserted;
    return $inserted;
}

sub pop {
    my ($self,$count) = @_;
    $count ||= 1;
    if (! eval { $self->_check_pid; 1 } ) {
        carp "Forks::Queue::pop operation failed: $@";
        return;
    }
    local $/ = EOL;
    my @return;
    while (@return == 0) {
        my $h;
        do {
            _SYNC { $self->_read_header } $self;
        } while (!$self->{_avail} && !$self->{_end} && 
                 1 + _SLEEP($self)); #sleep($Forks::Queue::SLEEP_INTERVAL || 1));

        return if $self->{_end} && !$self->{_avail};

        _SYNC {
            $self->_read_header;
            seek $self->{_fh}, $self->{_tell}, 0;
            if ($self->{_avail} <= $count) {
                my @items = readline($self->{_fh});
		chomp(@items);
                @return = map dejsonize($_), @items;
                truncate $self->{_fh}, $self->{_tell};
                $self->{_count} -= @items;
            } else {
                my $pos = $self->{_pos};
                while ($pos + $count < $self->{_count}) {
                    scalar readline($self->{_fh});
                    $pos++;
                }
                my $eof = tell $self->{_fh};
                my @items = readline($self->{_fh});
                truncate $self->{_fh}, $eof;
                $self->{_count} -= @items;
                chomp(@items);
                @return = map dejsonize($_), @items;
            }
            $self->_write_header;
        } $self;
    }
    $self->_notify if @return;
    if (!wantarray && @_ < 2) {
        return $return[0];
    } else {
        return @return;
    }
}

sub pop_nb {
    my ($self,$count) = @_;
    $count ||= 1;
    if (! eval { $self->_check_pid; 1 } ) {
        carp "Forks::Queue::pop operation failed: $@";
        return;
    }
    local $/ = EOL;
    my @return;
    my $h;
    _SYNC { $self->_read_header } $self;
    return if $self->{_end} && !$self->{_avail};

    _SYNC {
        $self->_read_header;

        seek $self->{_fh}, $self->{_tell}, 0;
        if ($self->{_avail} <= $count) {
            my @items = readline($self->{_fh});
            chomp(@items);
            @return = map dejsonize($_), @items;
            truncate $self->{_fh}, $self->{_tell};
            $self->{_count} -= @items;
            $self->_write_header;
            return;
        }

        my $pos = $self->{_pos};
        while ($pos + $count < $self->{_count}) {
            scalar readline($self->{_fh});
            $pos++;
        }
        my $eof = tell $self->{_fh};
        my @items = readline($self->{_fh});
        truncate $self->{_fh}, $eof;
        $self->{_count} -= @items;
        chomp(@items);
        @return = map dejsonize($_), @items;
        $self->_write_header;
        return;
    } $self;
    $self->_notify if @return;
    if (!wantarray && @_ < 2) {
        return $return[0];
    } else {
        return @return;
    }
}

# MagicLimit: a tie class to allow $q->limit to work as an lvalue

sub Forks::Queue::File::MagicLimit::TIESCALAR {
    my ($pkg,$obj) = @_;
    return bless \$obj,$pkg;
}

sub Forks::Queue::File::MagicLimit::FETCH {
    return ${$_[0]}->{limit};
}

sub Forks::Queue::File::MagicLimit::STORE {
    my ($tie,$val) = @_;
    my $queue = $$tie;
    my $oldval  = $queue->{limit};
    $queue->{limit} = $val;
    _SYNC { $queue->_write_header } $queue;
    return $oldval;
}

sub limit :lvalue {
    my $self = shift;
    if (!$self->{_limit_magic}) {
        tie $self->{_limit_magic},'Forks::Queue::File::MagicLimit', $self;
    }
    _SYNC { $self->_read_header } $self;
    if (@_) {
        $self->{limit} = shift @_;
        if (@_) {
            $self->{on_limit} = shift @_;
        }
        _SYNC { $self->_write_header } $self;
    }
    return $self->{_limit_magic};
}

sub _DUMP {
    my ($self,$fh_dump) = @_;
    $fh_dump ||= *STDERR;
    open my $fh_qdata, '<', $self->{file};
    print {$fh_dump} <$fh_qdata>;
    close $fh_qdata;
}

my $id = 0;
sub _impute_file {
    my $base = $0;
    $base =~ s{.*[/\\](.)}{$1};
    $base =~ s{[/\\]$}{};
    $id++;
    my $file;
    my @candidates;
    if ($^O eq 'MSWin32') {
        @candidates = (qw(C:/Temp C:/Windows/Temp));
    } else {
        @candidates = qw(/tmp /var/tmp);
    }

    # try hard to avoid using an NFS drive
    for my $candidate ($ENV{FORKS_QUEUE_DIR},
                       $ENV{TMPDIR}, $ENV{TEMP},
                       $ENV{TMP}, @candidates,
                       $ENV{HOME}, ".") {
        next if !defined($candidate);
        if (-d $candidate && -w _ && -x _) {
            $file //= "$candidate/.fq-$$-$id-base";
            next if Forks::Queue::Util::__is_nfs($candidate);
            return "$candidate/.fq-$$-$id-$base";
        }
    }

    carp "Forks::Queue::File: queue file $file might be on an NFS filesystem!";
    return $file;
}

1;

=head1 NAME

Forks::Queue::File - file-based implementation of Forks::Queue

=head1 VERSION

0.12

=head1 SYNOPSIS

    my $q = Forks::Queue::File->new( file => "queue-file" );
    $q->put( "job1" );
    $q->put( { name => "job2", task => "do something", data => [42,19] } );
    ...
    $q->end;
    for my $w (1 .. $num_workers) {
        if (fork() == 0) {
            my $task;
            while (defined($task = $q->get)) {
                ... perform task in child ...
            }
            exit;
        }
    }

=head1 METHODS

See L<Forks::Queue> for an overview of the methods supported by
this C<Forks::Queue> implementation.

=head2 new

=head2 $queue = Forks::Queue::File->new( %opts )

=head2 $queue = Forks::Queue->new( impl => 'File', %opts )

The C<Forks::Queue::File> constructor recognized the following configuration
options.

=over 4

=item * file

The name of the file to use to score queue data and metadata.
If omitted, a temporary filename is chosen.

It is strongly recommended not to use a file that would reside on an
NFS filesystem, since these filesystems have notorious difficulty
with synchronizing files across processes.

=item * style

=item * limit

=item * on_limit

=item * join

=item * persist

See L<Forks::Queue/"new"> for descriptions of these options.

=back

=head1 BUGS AND LIMITATIONS

As with anything that requires C<flock>, you should avoid allowing the
queue file to reside on an NFS drive.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017-2019, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut

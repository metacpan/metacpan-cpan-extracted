package IPC::Transit;
$IPC::Transit::VERSION = '1.161450';
use strict;use warnings;
use 5.006;
use IPC::Transit::Internal;
use Storable;
use Data::Dumper;
use JSON;
use Sereal::Encoder;
use Sereal::Decoder qw(looks_like_sereal decode_sereal);
use Sys::Hostname;
use HTTP::Lite;
use File::Temp qw/tempfile/;
use Tie::DNS;
use Crypt::Sodium;
use MIME::Base64;

use vars qw(
    $config_file $config_dir $large_transit_message_dir
    $local_queues
);

$IPC::Transit::my_keys = {
    default => 'ftlMCefNymrF66r2VlFBgHYbWRZqSJPzVg4Vz/I86UQ='
};
$IPC::Transit::public_keys = {
    default => 'vbqcxUUGIOvIKzpFWyBbYrSTsmSGj+/zlkF9H3tJ0DI='
};

our $large_transit_message_dir = '/tmp/transit_large_messages'
    unless $IPC::Transit::large_transit_message_dir;

##sorry, gotta have this temp dir in a known location
mkdir $large_transit_message_dir unless -d $large_transit_message_dir;
chmod 0777, $large_transit_message_dir;  ##sorry, it has to be 0777 :(

our $wire_header_arg_translate = {
    destination => 'd',
    destination_qname => 'q',
    compression => 'c',
    serializer => 's',
    message_length => 'l',
    local_filename => 'f',
    ttl => 't',
    nonce => 'n',
    source => 'S',
};
our $max_message_size = 4096 unless $IPC::Transit::max_message_size;

{
my %dns;
my $cache;
my $ts;
sub cached_dns {
    my $thing = shift;
    return $thing unless $thing;
    if(not $ts) {
        $ts = time;
        $cache = {};
        tie %dns, 'Tie::DNS' unless %dns;
    }
    if(time > $ts + 10) {
        $ts = time;
        $cache = {};
    }
    my $ret = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 2;
        return $dns{$thing};
    };
    alarm 0;
    $ret = $thing unless $ret;
    return $ret;
}
}

#This validates some allowed values of wire header arguments
our $wire_header_args = {
    s => {  #serializer
        json => 1,
        sereal => 1,
        yaml => 1,
        storable => 1,
        dumper => 1,
    },
    c => {  #compression
        zlib => 1,
        snappy => 1,
        none => 1
    },
    d => 1, #destination address
    t => 1, #hop TTL
    q => 1, #destination qname
    l => 1, #length of the message itself
    f => 1, #local_filename, optionally a path on the filesystem where the message can be found
    t => 1, #Time To Live
    #for crypto
    n => 1, #nonce
    S => 1, #source
};
our $std_args = {
    message => 1,
    qname => 1,
    nowait => 1,
    encrypt => 1,
};

sub send {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::send: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};
    die "IPC::Transit::send: parameter 'qname' required"
        unless $qname;
    die "IPC::Transit::send: parameter 'qname' must be a scalar"
        if ref $qname;
    my $message = $args{message};
    die "IPC::Transit::send: parameter 'message' required"
        unless $message;
    die "IPC::Transit::send: parameter 'message' must be a HASH reference"
        if ref $message ne 'HASH';
    $message->{'.ipc_transit_meta'} = {} unless $message->{'.ipc_transit_meta'};
    $message->{'.ipc_transit_meta'}->{send_ts} = time;
    if($args{encrypt} and not $args{destination}) {
        die "IPC::Transit::send: parameter 'destination' must exist if encryption is selected";
    }
    if($args{destination}) {
        #let's take a stab at efficiently getting destination to either an
        #IP address or a FQDN
        #If destination has less then tree .'s in it, then we will do a DNS
        #lookup on it, and if that returns anything, replace it
        if(not $args{no_dns_normalize}) {
            if($args{destination} =~ tr/\./\./ < 3) {
                my $new = cached_dns($args{destination});
                $args{destination} = $new if $new;
            }
        }
        $args{destination_qname} = $args{qname};
        $args{qname} = 'transitd';
        $args{ttl} = '9' unless $args{ttl};

        return _deliver_non_local($qname, \%args);
    }

    #begin the hard work of figuring out if this message should be sent as
    #local delivery or not.
    #overall default is to non-local delivery

    #the overrides in .ipc_transit_meta in the message takes precidence
    #over previous calls to ::local_queue and/or ::no_local_queue

    #insides of overrides, the force_local and force_non_local
    #take precidence over the default_to.

    #algo
    #1. absolute override goes to the invocation: override_local/
    #   override_non_local
    #2. next, look at force_* in the message.  If they conflict, then we go
    #   with force_non_local.
    #3. lacking any instructions there, we go with the default_to directive,
    #   if any, in the message
    #4. lacking that, we go with what's been set with ::local_queue and/or
    #  ::no_local_queue
    #5. And finally, non-local delivery


    #1a:
    return _deliver_non_local($qname, \%args) if $args{override_local};

    #1b:
    return _deliver_local($qname, \%args) if $args{override_non_local};

    #2a:
    if(     $message->{'.ipc_transit_meta'}->{overrides} and
            $message->{'.ipc_transit_meta'}->{overrides}->{force_non_local} and
            $message->{'.ipc_transit_meta'}->{overrides}->{force_non_local}->{$args{qname}}) {
        return _deliver_non_local($qname, \%args);
    }

    #2b:
    if(     $message->{'.ipc_transit_meta'}->{overrides} and
            $message->{'.ipc_transit_meta'}->{overrides}->{force_local} and
            $message->{'.ipc_transit_meta'}->{overrides}->{force_local}->{$args{qname}}) {
        return _deliver_local($qname, \%args);
    }

    #3a:
    if(     $message->{'.ipc_transit_meta'}->{overrides} and
            $message->{'.ipc_transit_meta'}->{overrides}->{default_to} and
            $message->{'.ipc_transit_meta'}->{overrides}->{default_to} eq 'local'
    ) {
        return _deliver_local($qname, \%args);
    }

    #3b:
    if(     $message->{'.ipc_transit_meta'}->{overrides} and
            $message->{'.ipc_transit_meta'}->{overrides}->{default_to} and
            $message->{'.ipc_transit_meta'}->{overrides}->{default_to} eq 'non-local'
    ) {
        return _deliver_non_local($qname, \%args);
    }

    #4:
    if(     $local_queues and
            $local_queues->{$qname}) {
        return _deliver_local($qname, \%args);
    }

    #5:
    return _deliver_non_local($qname, \%args);
}

sub _deliver_local {
    my ($qname, $args) = @_;
    push @{$local_queues->{$qname}}, $args;
    return $args;
}

sub _get_tmp_file {
    my ($fh, $filename) = tempfile(SUFFIX => '.transit', DIR => $large_transit_message_dir);
    die 'failed to create tmpfile' unless -e $filename;
    return ($fh, $filename);
}


sub _deliver_non_local {
    my ($qname, $args) = @_;
    my $to_queue = IPC::Transit::Internal::_initialize_queue(%$args);
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 2;
        pack_message($args);
    };
    alarm 0;
    if($@) {
        print STDERR "IPC::Transit::_deliver_non_local: pack_message failed: $@\n";
        unlink $args->{local_filename}
            if $args->{local_filename} and -e $args->{local_filename};
        return undef;
    }
    my $ret = $to_queue->snd(1,$args->{serialized_wire_data}, IPC::Transit::Internal::_get_flags('nonblock'));
    unlink $args->{local_filename}
        if not $ret and $args->{local_filename};
    return $ret;
}

sub stats {
    my $info = IPC::Transit::Internal::_stats();
    return $info;
}
sub stat {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::stat: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};
    if(not $args{override_local} and $local_queues and $local_queues->{$qname}) {
        return {
            qnum => scalar @{$local_queues->{$qname}}
        };
    }
    die "IPC::Transit::stat: parameter 'qname' required"
        unless $qname;
    die "IPC::Transit::stat: parameter 'qname' must be a scalar"
        if ref $qname;
    my $info = IPC::Transit::Internal::_stat(%args);
}

sub receive {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::receive: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};

    die "IPC::Transit::receive: parameter 'qname' required"
        unless $qname;
    die "IPC::Transit::receive: parameter 'qname' must be a scalar"
        if ref $qname;
    if(     not $args{override_local} and
            $local_queues and
            $local_queues->{$qname}) {
        my $m = shift @{$local_queues->{$qname}};
        return $m->{message};
    }
    my $ret = eval {
        my $flags = IPC::Transit::Internal::_get_flags('nowait') if $args{nonblock};
        my $from_queue = IPC::Transit::Internal::_initialize_queue(%args);
        my $ref = { #just doing this so we can pass the possibly big serialized
                #data around as a reference
            serialized_wire_data => '',
        };
        if(not $from_queue->rcv($ref->{serialized_wire_data}, 102400000, 0, $flags)) {
            return undef;
        }
        if(not defined $ref->{serialized_wire_data}) {
            print STDERR "IPC::Transit::receive: received message had no data";
            return undef;
        }

        my ($header_length, $wire_headers) = _parse_wire_header($ref);
        if(not defined $wire_headers) {
            print STDERR 'IPC::Transit::receive: received message had no wire headers: ' . substr($ref->{serialized_wire_data}, 0, 30) . "\n";
            return undef;
        }
        if(not defined $header_length) {
            print STDERR 'IPC::Transit::receive: received message had no header length: ' . substr($ref->{serialized_wire_data}, 0, 30) . "\n";
            return undef;
        }
        sync_serialized_wire_data($wire_headers, $ref);

        my $message = {
            wire_headers => $wire_headers,
            serialized_message => substr(
                $ref->{serialized_wire_data},
                $header_length + length($header_length) + 1,
                9999999, # :(
            ),
        };
        my $used_default_public = 1;
        if($message->{wire_headers}->{n}) {
            #we be encrypted
            #validate $IPC::Transit::my_keys->{private}
            #
            my $source = $message->{wire_headers}->{S};
            my $public_key;
            if($IPC::Transit::public_keys->{$source}) {
                $public_key = $IPC::Transit::public_keys->{$source};
                $used_default_public = 0;
            } else {
                $public_key = $IPC::Transit::public_keys->{default};
            }
            my @private_keys = ($IPC::Transit::my_keys->{default});
            push @private_keys, $IPC::Transit::my_keys->{private}
                if $IPC::Transit::my_keys->{private};
            my $nonce = decode_base64($message->{wire_headers}->{n});
            my $public_keys;
            if(not ref $public_key) {
                $public_keys = [$public_key];
            } else {
                $public_keys = $public_key;
            }
            push @$public_keys, $IPC::Transit::public_keys->{default};
            my $cleartext;
            PUBLIC:
            foreach my $public (@$public_keys) {
                foreach my $private_key (@private_keys) {
                    $cleartext = crypto_box_open(
                        $message->{serialized_message},
                        $nonce,
                        decode_base64($public),
                        decode_base64($private_key),
                    );
                    last PUBLIC if $cleartext;
                }
            }
            $message->{serialized_message} = $cleartext;
        }
        return undef unless _thaw($message);
        $message->{message}->{'.ipc_transit_meta'}->{encrypt_source} =
            $message->{wire_headers}->{S} if $message->{wire_headers}->{S};
        $message->{message}->{'.ipc_transit_meta'}->{encrypt_source} = 'default'
            if $used_default_public;
        return $message if $args{raw};
        return $message->{message};
    };
    die $@ if $@;
    return $ret;
}

sub sync_serialized_wire_data {
    my ($wire_headers, $ref) = @_;
    if($wire_headers->{f} and -r $wire_headers->{f}) {
        eval {
            local $SIG{ALRM} = sub { die "timed out\n"; };
            alarm 5;
            open my $fh, '<', $wire_headers->{f}
                or die "failed to open $wire_headers->{f} for reading: $!";
            read $fh, $ref->{serialized_wire_data}, 1024000000
                or die "failed to read from $wire_headers->{f}: $!";
            close $fh or die "failed to close $wire_headers->{f}: $!";
        };
        alarm 0;
        unlink $wire_headers->{f};
    }
}

sub post_remote {
    #This is very simple, first-generation logic.  It assumes that every
    #message that is received that has a qname set is destined for off box.

    #so here, we want to post this message to the destination over http
    my $message = shift;
    my $http = HTTP::Lite->new;
    my $vars = {
        message => $message->{serialized_wire_data},
    };
    $http->prepare_post($vars);
    my $url = 'http://' . $message->{message}->{'.ipc_transit_meta'}->{destination} . ':9816/message';
    my $req;
    eval {
        $req  = $http->request($url)
            or die "Unable to get document: $!";
    };
    print STDERR "IPC::Transit::post_remote: (\$url=$url) failed: $@\n" if $@;
    return $req;
}

sub no_local_queue {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::no_local_queue: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};
    delete $local_queues->{$qname};
    return 1;
}

sub queue_exists {
    my $qname = shift;
    return IPC::Transit::Internal::_queue_exists($qname);
}

sub _parse_wire_header {
    my $ref = shift;
    if($ref->{serialized_wire_data} !~ /^(\d+)/sm) {
        print STDERR 'IPC::Transit::_parse_wire_header: malformed message received: ' . substr($ref->{serialized_wire_data}, 0, 60) . "\n";
        return (undef, undef);
    }
    my $header_length = $1;
    return (
        $header_length,
        deserialize_wire_meta(
            substr( $ref->{serialized_wire_data},
                    length($header_length) + 1,
                    $header_length
            )
        ),
    );
}
sub local_queue {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::local_queue: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};
    $local_queues = {} unless $local_queues;
    $local_queues->{$qname} = [] unless $local_queues->{$qname};
    return 1;
}

sub pack_message {
    my $args = shift;
    $args->{message}->{'.ipc_transit_meta'} = {}
        unless $args->{message}->{'.ipc_transit_meta'};
    foreach my $key (keys %$wire_header_arg_translate) {
        next unless $args->{$key};
        $args->{$wire_header_arg_translate->{$key}} = $args->{$key};
    }
    foreach my $key (keys %$args) {
        next if $wire_header_args->{$key};
        next if $std_args->{$key};
        $args->{message}->{'.ipc_transit_meta'}->{$key} = $args->{$key};
    }
    if($args->{encrypt}) {
        $args->{message}->{'.ipc_transit_meta'}->{destination} = $args->{destination};
    }
    $args->{message}->{'.ipc_transit_meta'}->{source_hostname} = _get_my_hostname();
    if($args->{encrypt}) {
        my $sender = _get_my_hostname();
        if(not $sender) {
            die 'encrypt selected but unable to determine hostname.  Set $IPC::Transit::my_hostname to override';
        }
    }
    if($args->{encrypt}) {
        my $nonce = crypto_box_nonce();
        $args->{nonce} = encode_base64($nonce);

        my $my_private_key;
        if($IPC::Transit::my_keys->{private}) {
            $my_private_key = $IPC::Transit::my_keys->{private};
            $args->{message}->{'.ipc_transit_meta'}->{signed_destination} = 'my_private';
        } else {
            $my_private_key = $IPC::Transit::my_keys->{default};
            $args->{message}->{'.ipc_transit_meta'}->{signed_destination} = 'default';
        }
        my $their_public_key;
        if($IPC::Transit::public_keys->{$args->{destination}}) {
            $their_public_key = $IPC::Transit::public_keys->{$args->{destination}};
        } else {
            $their_public_key = $IPC::Transit::public_keys->{default};
        }
        $args->{serialized_message} = _freeze($args);
        my $cipher_text = crypto_box(
            $args->{serialized_message},
            $nonce,
            decode_base64($their_public_key),
            decode_base64($my_private_key)
        );
        $args->{serialized_message} = $cipher_text;
        $args->{source} = _get_my_hostname();
    } else {
        $args->{serialized_message} = _freeze($args);
    }
    $args->{message_length} = length $args->{serialized_message};
    if($args->{message_length} > $IPC::Transit::max_message_size) {
        my $s;
        eval {
            my $fh;
            ($fh, $args->{local_filename}) = _get_tmp_file();
            $s = serialize_wire_meta($args);
            print $fh "$s$args->{serialized_message}"
                or die "failed to write to file $args->{local_filename}: $!";
            close $fh or die "failed to close $args->{local_filename}: $!";
            chmod 0666, $args->{local_filename};
        };
        if($@) {
            unlink $args->{local_filename};
            die "IPC::Transit::pack_message: failed: $@";
        }
        $args->{serialized_wire_data} = $s;
        return;
    }
    my $s = serialize_wire_meta($args);
    $args->{serialized_wire_data} = "$s$args->{serialized_message}";
    return;
}

sub serialize_wire_meta {
    my $args = shift;
    my $s = '';
    foreach my $key (keys %$args) {
        my $translated_key = $wire_header_arg_translate->{$key};
        if($translated_key and $wire_header_args->{$translated_key}) {
            if($wire_header_args->{$translated_key} == 1) {
                $s = "$s$translated_key=$args->{$key},";
            } elsif($wire_header_args->{$translated_key}->{$args->{$key}}) {
                $s = "$s$translated_key=$args->{$key},";
            } else {
                die "passed wire argument $translated_key had value of $args->{$translated_key} not of allowed type";
            }
        }
    }
    chop $s; #no trailing ,
    my $l = length $s;
    return "$l:$s";
}

sub deserialize_wire_meta {
    my $header = shift;
    my $ret = {};
    foreach my $part (split ',', $header) {
        my ($key, $val) = split '=', $part;
        $ret->{$key} = $val;
    }
    return $ret;
}

{
my $encoder;
sub _freeze {
    my $args = shift;
    $encoder = Sereal::Encoder->new() unless $encoder;
    if(not defined $args->{serializer} and $ENV{IPC_TRANSIT_DEFAULT_SERIALIZER}) {
        $args->{serializer} = $ENV{IPC_TRANSIT_DEFAULT_SERIALIZER};
    }
    if(not defined $args->{serializer} or $args->{serializer} eq 'json') {
        return encode_json $args->{message};
    } elsif($args->{serializer} eq 'sereal') {
        return $encoder->encode($args->{message});
    } elsif($args->{serializer} eq 'dumper') {
        return Data::Dumper::Dumper $args->{message};
    } elsif($args->{serializer} eq 'storable') {
        return Storable::freeze $args->{message};
    } else {
        die "_freeze: undefined serializer: $args->{serializer}";
    }
}
}

sub _thaw {
    my $args = shift;
    my $ret = eval {
        die 'passed serialized_message is falsy'
            unless $args->{serialized_message};
        if(not defined $args->{wire_headers}->{s} or $args->{wire_headers}->{s} eq 'sereal') {
            if(looks_like_sereal($args->{serialized_message})) {
                return $args->{message} = decode_sereal($args->{serialized_message});
            } else {
                return $args->{message} = decode_json($args->{serialized_message});
            }
        } elsif($args->{wire_headers}->{s} eq 'json') {
            return $args->{message} = decode_json($args->{serialized_message});
        } elsif($args->{wire_headers}->{s} eq 'dumper') {
            our $VAR1;
            eval $args->{serialized_message};
            return $args->{message} = $VAR1;
        } elsif($args->{wire_headers}->{s} eq 'storable') {
            return $args->{message} = Storable::thaw($args->{serialized_message});
        } else {
            die "undefined serializer: $args->{wire_headers}->{s}";
        }
    };
    my $err = $@;
    if($err) {
        if($args->{serialized_message}) {
            print STDERR "_thaw: failed: $err: $args->{serialized_message}\n";
        } else {
            print STDERR "_thaw: failed: $err: <undef>\n";
        }
    }
    return $ret;
}

sub gen_key_pair {
    my ($pk, $sk) = box_keypair();
    return (encode_base64($pk),encode_base64($sk));
}

{
my $hostname;
sub _get_my_hostname {
    return $IPC::Transit::my_hostname if $IPC::Transit::my_hostname;
    return $hostname if $hostname;
    {   my $ret = `hostname -f 2> /dev/null`;
        chomp $ret;
        if(length($ret) > 5) {
            $hostname = $ret;
        }
    }
    $hostname = hostname unless $hostname;
    return $hostname;
}
}
1;

__END__

=head1 NAME

IPC::Transit - A framework for high performance message passing

=head1 NOTES

The serialization is currently hard-coded to https://metacpan.org/pod/Sereal

=head1 SYNOPSIS

  use strict;
  use IPC::Transit;
  IPC::Transit::send(qname => 'test', message => { a => 'b' });

  #...the same or a different process on the same machine
  my $message = IPC::Transit::receive(qname => 'test');

  #remote transit
  remote-transitd &  #run 'outgoing' transitd gateway
  IPC::Transit::send(qname => 'test', message => { a => 'b' }, destination => 'some.other.box.com');

  #On 'some.other.box.com':
  plackup --port 9816 $(which remote-transit-gateway.psgi) &  #run 'incoming' transitd gateway
  my $message = IPC::Transit::receive(qname => 'test');

=head1 DESCRIPTION

This queue framework has the following goals:
    
=over 4

=item * Serverless

=item * High Throughput

=item * Usually Low Latency

=item * Relatively Good Reliability

=item * CPU and Memory efficient

=item * Cross UNIX Implementation

=item * Multiple Language Compability

=item * Very few module dependencies

=item * Supports old version of Perl

=item * Feature stack is modular and optional

=back

This queue framework has the following anti-goals:

=over 4

=item * Guaranteed Delivery

=back

=head1 FUNCTIONS

=head2 send(qname => 'some_queue', message => $hashref, [destination => $destination, serializer => 'some serializer', crypto => 1 ])

This sends $hashref to 'some_queue'.  some_queue may be on the local
box, or it may be in the same process space as the caller.

This call will block until the destination queue has enough space to
handle the serialized message.

The destination argument is optional.  If defined, it is the remote host
will receive the message.

The serialize argument is optional, and defaults to Sereal.  It is
over-ridden with the IPC_TRANSIT_DEFAULT_SERIALIZER environmental
variable.  The following serializers are available:

serial, json, yaml, storable, dumper

NB: there is no need to define the serialization type in receive.  It is
automatically detected and utilized.

The crypto argument is optional.  See below for details.

=head2 receive(qname => 'some_queue', nonblock => [0|1], override_local => [0|1])

This function fetches a hash reference from 'some_queue' and returns it.
By default, it will block until a reference is available.  Setting nonblock
to a true value will cause this to return immediately with 'undef' is
no messages are available.

override_local defaults to false; if set to true, the receive will always
do a non-process local receive.


=head2 stat(qname => 'some_queue')

Returns various stats about the passed queue name, per IPC::Msg::stat:

 print Dumper IPC::Transit::stat(qname => 'test');
 $VAR1 = {
          'ctime' => 1335141770,
          'cuid' => 1000,
          'lrpid' => 0,
          'uid' => 1000,
          'lspid' => 0,
          'mode' => 438,
          'qnum' => 0,
          'cgid' => 1000,
          'rtime' => 0,
          'qbytes' => 16384,
          'stime' => 0,
          'gid' => 1000
 }

=head2 stats()

Return an array of hash references, each containing the information 
obtained by the stat() call, one entry for each queue on the system.

=head2 CRYPTO

On send(), if the crypto argument is set, IPC::Transit will sign and
encrypt the message before it is sent.  The necessary configs, including
relevant keys, are set in some global variables.

See an actual example of this in action under ex/crypto.pl

Please note that this module does not directly assist with the always
onerous task of key distribution.

=head3 $IPC::Transit::my_hostname

If not set, this defaults to the output of the module Sys::Hostname.
This value is placed into the message by the sender, and used by the
receiver to lookup the public key of the sender.

=head3 $IPC::Transit::my_keys

This is a hash reference initially populated, in the attribute 'default',
with the private half of a default key pair.  For actual secure
communication, a new key pair must be generated on both sides, and the
sender's private key needs to be placed here:

  $IPC::Transit::my_keys->{private} = $real_private_key

=head3 $IPC::Transit::public_keys

As above, this is a hash reference initially populated, in the attribute
'default', with the public half of a default key pair.  For actual secure
communication, a new key pair must be generated on both sides, and the
receiver's public key needs to be placed here:

  $IPC::Transit::public_keys->{$receiver_hostname} = $real_public_key_from_receiver

$receiver_hostname must exactly match what is passed into the 'destination'
field of send().

All of these keys must be base 64 encoded 32 byte primes, as used by
the Crypto::Sodium package.

=head3 IPC::Transit::gen_key_pair()

This returns a two element array representing a public/privte key pair,
properly base64 encoded for use in $IPC::Transit::my_keys and
$IPC::Transit::public_keys

=head1 SEE ALSO

A zillion other queueing systems.

=head1 TODO

Implement nonblock flag for send()

=head1 BUGS

Patches, flames, opinions, enhancement ideas are all welcome.

I am not satisfied with not supporting Windows, but it is considered
secondary.  I am open to the possibility of adding abstractions for this
kind of support as long as it doesn't impact the primary goals.

=head1 COPYRIGHT

Copyright (c) 2012, 2013, 2016 Dana M. Diederich. All Rights Reserved.

=head1 LICENSE

This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=head1 AUTHOR

Dana M. Diederich <dana@realms.org>

=cut

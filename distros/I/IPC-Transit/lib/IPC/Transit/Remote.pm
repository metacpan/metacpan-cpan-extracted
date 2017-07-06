package IPC::Transit::Remote;
$IPC::Transit::Remote::VERSION = '1.171860';
use strict;use warnings;
use IPC::Transit;
use Data::Dumper;
use Sys::Hostname;
use HTTP::Async;
use HTTP::Request;

our $debug = 0;

my $all_possible_mes = eval {
    $ENV{PATH}="/usr/sbin:/sbin:$ENV{PATH}" unless $ENV{PATH} =~ m|/sbin|;
    my $hostname = hostname;
    my $ret = {};
    foreach (`ifconfig -a` =~ /inet (\S+) /g) {
        $ret->{$_} = 1;
        my $rev = IPC::Transit::cached_dns($_);
        $ret->{$rev} = 1 if $rev;
    }
    $ret->{'127.0.0.1'} = 1;
    $ret->{localhost} = 1;
    $ret->{$hostname} = 1;
    if($ENV{TRANSIT_EXTRA_MES}) {
        foreach my $me (split ':', $ENV{TRANSIT_EXTRA_MES}) {
            $ret->{$me} = 1;
        }
    }
    return $ret;
};
print STDERR 'IPC::Transit::Remote: $all_possible_mes= ';
print STDERR Data::Dumper::Dumper $all_possible_mes;

{
my $ts;
sub default_info_callback {
    my $async = shift;
    my $destinations = shift;
    $ts = 0 unless defined $ts;
    my $time = time;
    return if $time - 1 < $ts;
    $ts = $time;
    my $to_send_count = $async->to_send_count;
    my $to_return_count = $async->to_return_count;
    my $in_progress_count = $async->in_progress_count;
    my $total_count = $async->total_count;
    my $info = $async->info;
    #print STDERR "\$to_send_count=$to_send_count \$to_return_count=$to_return_count \$in_progress_count=$in_progress_count \$total_count=$total_count\n\$info=$info\n";
    print STDERR "$info\n" if $debug;;
    while(my($key, $value) = each %{$destinations}) {
        print STDERR "Dest: $key=" . (scalar @{$value->{messages}}) . "\n" if $debug;
    }
    print STDERR Data::Dumper::Dumper $destinations if $debug;
}
}

our $config = {
    port => 9816,
    path => '/sendMessage',
    protocol => 'http',
    remote_timeout => 5,
    url_callback => undef,
    proxy_callback => undef,
    info_callback => \&default_info_callback,
    transit_sending_host => hostname,
    handle_interval_interval => 1,
    max_return_message_bytes => 10000000,
    http_async_constructor_args => {
        ssl_options => { SSL_verify_mode => 'SSL_VERIFY_NONE' },
    },
    is_me => sub {
        my $dest = shift;
        return undef unless $dest;
        return $all_possible_mes->{$dest};
    },
};

sub handle_raw_messages {
    my $ref = shift;
    #the actual incoming data is in $ref->{serialized_wire_data}
    #we do it indirectly because that might be very big, and we don't want
    #to copy it around
    my $message_ct = 0;
    my $total_length = length $ref->{serialized_wire_data};
    while(my $new = get_next_raw_message($ref)) {
        $message_ct++;
        my $send_to_qname = 'transitd';
        if($config->{is_me}->($new->{wire_headers}->{d})) {
            $send_to_qname = $new->{wire_headers}->{q};
        }
        my $to_queue = IPC::Transit::Internal::_initialize_queue(qname => $send_to_qname);
        my $ret = $to_queue->snd(1,$new->{serialized_wire_data}, IPC::Transit::Internal::_get_flags('nonblock'));
        #what to do if this fails?  Good question.
        #Maybe we should fail the whole operation, if we're called over http.
        #Maybe we can call this in blocking mode, but then we have to be
        #careful about timing out so we don't fill up with http processes.
        #XXX consider

        #Also we need to think about implementing arge message support again
        #on this side.
    }
    return ($message_ct, $total_length)
}

sub get_proxy_send {
    my $transit_sending_host = shift;

    #common case: we have no messages to proxy send, so we return
    #nothing
    return '' unless IPC::Transit::queue_exists($transit_sending_host);

    my $return_messages = '';

    my $from_queue = IPC::Transit::Internal::_initialize_queue(qname => $transit_sending_host);
    my $flags = IPC::Transit::Internal::_get_flags('nowait');
    while(1) {
        $from_queue->rcv(my $serialized_wire_data, 102400000, 0, $flags);
        last unless $serialized_wire_data;
        my $ref = {
            serialized_wire_data => $serialized_wire_data
        };
        my ($header_length, $wire_headers) = IPC::Transit::_parse_wire_header($ref);
        IPC::Transit::sync_serialized_wire_data($wire_headers, $ref);
        $return_messages .= $ref->{serialized_wire_data};
        last if length $return_messages > $config->{max_return_message_bytes};
    }
    return $return_messages;
}

sub get_next_raw_message {
    my $ref = shift;
    return undef unless $ref->{serialized_wire_data};
    my $new = {
        header_length => 0,
        wire_headers => {},
        serialized_wire_data => 'abc',
    };
    ($new->{header_length}, $new->{wire_headers}) = IPC::Transit::_parse_wire_header($ref);
    return undef unless $new->{wire_headers};
    $new->{serialized_wire_data} = substr(
        $ref->{serialized_wire_data},
        0,
        $new->{header_length} + length($new->{header_length}) + 1 + $new->{wire_headers}->{l},
        ''
    );
    #print STDERR Data::Dumper::Dumper $new;
    return $new;
}

sub _post_proxy {
    my $dest = shift;
    my $messages = shift;
    #I believe all we need to do here is put them on a qname = $dest
    #messages is an array REF of raw messages, serialized_wire_data
    #if we return false here, then the messages will stay in the parent
    #array and be tried again later
    my $to_queue = IPC::Transit::Internal::_initialize_queue(qname => $dest);
    foreach my $serialized_wire_data (@{$messages}) {
        $to_queue->snd(1,$serialized_wire_data, IPC::Transit::Internal::_get_flags('nonblock'));
    }
    #for now, let's never fail
    return 1;
}


{
my $destinations;
my $async;
my $ct;
sub _setup_async {
    if(not $async) {
        $ct = 0;
        $async = HTTP::Async->new(
            %{$config->{http_async_constructor_args}}
        );
        $async->timeout($config->{remote_timeout});
    }
    $ct++;
    if($ct > 500000) {
        print STDERR "IPC::Transit::Remote::_setup_async: resetting HTTP::Async object after 500000 uses\n";
        undef $async;
        $ct = 1;
    }
}
sub get_destinations {
    return $destinations;
}
sub _init_dest {
    my $dest = shift;
    _setup_async();
    $destinations = {} unless $destinations;
    $destinations->{$dest} = {
        messages => [],
        total_send_ct => 0,
        total_byte_sent_ct => 0,
        codes => {},
    } unless $destinations->{$dest};
}
sub _set_code_stats {
    my $dest = shift;
    my $response = shift;
    _setup_async();
    my $code = $response->code;
    _init_dest($dest);
    $destinations->{$dest}->{codes}->{$code} = {
        ct => 0,
        last_status_line => '',
    } unless $destinations->{$dest}->{codes}->{$code};
    $destinations->{$dest}->{codes}->{$code}->{ct}++;
    $destinations->{$dest}->{codes}->{$code}->{last_status_line} = $response->status_line;
}
sub add_to_destination {
    my ($dest, $ref) = @_;
    _setup_async();
    #print STDERR "remote-transitd: Adding message to destination $dest\n";
    $config->{info_callback}->($async, $destinations)
        if $config->{info_callback};
    _init_dest($dest);
    push @{$destinations->{$dest}->{messages}}, $ref->{serialized_wire_data};
}
{
my $ts;
sub handle_interval {
    _setup_async();
    $config->{info_callback}->($async, $destinations)
        if $config->{info_callback};
    if($async->not_empty) {
        while(my $response = $async->next_response) {
            #$response->content contains all of the messages returned by
            #proxy, if any
            my $dest = $response->{_request}->header('TRANSIT_DESTINATION_HOST');
            _set_code_stats($dest, $response);
            if(not $response->is_success) {
                next;
            }
            my $ref = {
                serialized_wire_data => $response->content
            };
            #for now, handle the old (and grossly invalid) messages right away
            if(     $ref->{serialized_wire_data} and
                    $ref->{serialized_wire_data} !~ /^\d+/) {
                print STDERR 'IPC::Transit::Remote::handle_interval: received a grossly mis-formatted message, these are the first 40 characters: ' . substr($ref->{serialized_wire_data}, 0, 40) . "\n";
                next;
            }
            eval {
                my ($message_ct, $total_length) = IPC::Transit::Remote::handle_raw_messages($ref);
            };
            if($@) {
                if($ref->{serialized_wire_data}) {
                    print STDERR "IPC::Transit::Remote::handle_interval failed: $@: $ref->{serialized_wire_data}\n";
                } else {
                    print STDERR "IPC::Transit::Remote::handle_interval failed: $@: <undef>\n";
                }
            }
        }
    }
    my $time = time;
    $ts = $time unless defined $ts;
    return if $time - $config->{handle_interval_interval} < $ts;
    $ts = $time;
    foreach my $dest (keys %{$destinations}) {
        my $message_ct = scalar @{$destinations->{$dest}->{messages}};
        next unless $message_ct;
        if($config->{proxy_callback} and $config->{proxy_callback}->($dest)) {
            if(_post_proxy($dest, $destinations->{$dest}->{messages})) {
                $destinations->{$dest}->{messages} = [];
            }
            next;
        }
        my $all_messages = join '', @{$destinations->{$dest}->{messages}};
        my $url = "$config->{protocol}://$dest:$config->{port}$config->{path}";
        $url = $config->{url_callback}->($dest)
            if $config->{url_callback};
        $destinations->{$dest}->{messages} = [];
        $async->add(
            HTTP::Request->new(
                POST => $url,
                [   'TRANSIT_SENDING_HOST' => $config->{transit_sending_host},
                    'TRANSIT_DESTINATION_HOST' => $dest,
                ],
                $all_messages
            )
        );
        $destinations->{$dest}->{total_send_ct} += $message_ct;
        $destinations->{$dest}->{total_byte_sent_ct} += length $all_messages;
        #we need logic or something here (and elsewhere) to handle the case
        #where the request fails.
        #this means that while there are pending requests, we should probably
        #not do additional requests, so that if the request fails, we will
        #be able to put the data back.
        #or better yet, don't take the data from the array until the request
        #comes back successfully.
    }
}
}
}

1;

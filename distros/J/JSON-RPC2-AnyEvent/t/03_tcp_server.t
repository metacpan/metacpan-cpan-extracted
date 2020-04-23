use strict;
use Test::More;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;

use JSON::RPC2::AnyEvent::Server::Handle;


my $srv = JSON::RPC2::AnyEvent::Server->new(
    echo => sub{
        my ($cv, $args) = @_;
        my $w; $w = AE::timer 1, 0, sub{ undef $w; $cv->send($args) };
    },
    sum => sub{
        my ($cv, $args) = @_;
        my $s = 0;
        $s += $_  foreach @$args;
        $cv->send($s);
    },
);
isa_ok $srv, 'JSON::RPC2::AnyEvent::Server', 'new object';


my $end_cv = AE::cv;

my $w = tcp_server undef, undef, sub {
    my ($fh, $host, $port) = @_;
    my $hdl = $srv->dispatch_fh($fh);  # This is equivalent to JSON::RPC2::AnyEvent::Server::Handle->new($srv, $fh)
    $hdl->on_end(sub{
        $hdl->destroy;
        $end_cv->send("OK");
    });
    $hdl->on_error(sub{
        my ($h, $fatal, $message) = @_;
        ok(0, $message);
        $hdl->destroy;
        $end_cv->send("NOK");
    });
}, sub{
    my (undef, $host, $port) = @_;
	$host = 'localhost'  if $host eq '0.0.0.0';  # Cygwin returns '0.0.0.0' for host.
    my $w; $w = AE::timer 1, 0, sub{
        undef $w;
        tcp_connect $host => $port, sub{
            my $hdl = AnyEvent::Handle->new(fh => shift);
            $hdl->push_write(json => {
                jsonrpc => "2.0",
                id      => 123,
                method  => 'echo',
                params   => ['echo please!'],
            });
            $hdl->push_write(json => {
                jsonrpc => "2.0",
                id      => 234,
                method  => 'sum',
                params   => [1..5],
            });
            my ($got123, $got234) = (0, 0);
            $hdl->on_read(sub{
                $hdl->push_read(json => sub{
                    my ($h, $res) = @_;
                    isa_ok $res, 'HASH';
                    if ( $res->{id} == 123 ) {
                        ok(!$got123, "id=123 is got more than once?");
                        $got123 = 1;
                        isa_ok $res->{result}, 'ARRAY';
                        is scalar @{$res->{result}}, 1;
                        is $res->{result}[0], "echo please!";
                    } elsif ( $res->{id} == 234 ) {
                        ok(!$got234, "id=234 is got more than once?");
                        $got234 = 1;
                        is $res->{result}, 15;
                    } else {
                        ok(0, "id is neigther 123 nor 234");
                        $end_cv->croak("something wrong");
                    }
                    $hdl->destroy  if $got123 && $got234;
                });
            });
        };
    };
};

is($end_cv->recv, "OK", "successfully complete");
done_testing;

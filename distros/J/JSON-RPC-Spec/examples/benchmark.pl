#!/usr/bin/env perl
use utf8;
use 5.012;
use Benchmark qw(:all);

use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON::RPC::Spec;

warn $JSON::RPC::Spec::VERSION;

my $run;
my $times = 1;
my $opt   = shift || '';

if ($opt eq '--run') {
    $run   = 1;
    $times = -3;
}

my $result = timethese(
    $times,
    {
        rpc => sub {
            my $rpc = JSON::RPC::Spec->new;

            $rpc->register(echo => sub { $_[0] });
            $rpc->parse(
                '{"jsonrpc": "2.0", "method": "echo", "params": "Hello, World!", "id": 1}'
            );
            $rpc->parse(
                '{"jsonrpc": "2.0", "method": "echo", "params": "Hello, World!"}'
            );
            $rpc->parse(
                '{"jsonrpc": "2.0", "method": "1", "params": "Hello, World!"}'
            );
        },
    }
);

__END__

v0.01
rpc:  3 wallclock secs ( 3.14 usr +  0.00 sys =  3.14 CPU) @ 4669.11/s (n=14661)

v0.02
rpc:  3 wallclock secs ( 3.19 usr +  0.00 sys =  3.19 CPU) @ 4669.59/s (n=14896)

v0.03
rpc:  3 wallclock secs ( 3.05 usr +  0.00 sys =  3.05 CPU) @ 4505.57/s (n=13742)

v1.0.0
rpc:  4 wallclock secs ( 3.29 usr +  0.00 sys =  3.29 CPU) @ 3899.39/s (n=12829)

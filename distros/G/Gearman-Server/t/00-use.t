use strict;
use warnings;

use version;
use Test::More;
use Test::Script;

my @mn = qw/
    Gearman::Server
    Gearman::Server::Client
    Gearman::Server::Listener
    Gearman::Server::Job
    /;

my $v = qv("v1.130.1");

foreach my $n (@mn) {
    use_ok($n);
    my $_v = eval '$' . $n . '::VERSION';
    is($_v, $v, "$n version is $v");
}

script_compiles_ok("bin/gearmand");

done_testing;



use warnings;
use strict;

use Test::More tests => 1;

my $package = 'HTTP::Server::Simple::Er';
use_ok('HTTP::Server::Simple::Er') or BAIL_OUT('cannot load HTTP::Server::Simple::Er');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta

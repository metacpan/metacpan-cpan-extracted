# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl HTTP-ClickHouse-Base.t'

#########################

use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('HTTP::ClickHouse::Base') };

my $chdb = HTTP::ClickHouse::Base->new(host => '127.0.0.1', port => 8123, debug => 1);

is ref($chdb), "HTTP::ClickHouse::Base";

is $chdb->{host}, '127.0.0.1';

is $chdb->{port}, 8123;

$chdb->_init;

is $chdb->{database}, 'default';

is $chdb->{nb_timeout}, 25;

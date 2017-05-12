# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl t/HTTP-ClickHouse.t'

#########################

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 7;
BEGIN { use_ok('HTTP::ClickHouse') };

require Net::HTTP::NB;
use IO::Socket::INET;
use Data::Dumper;
use IO::Select;
use Socket qw(TCP_NODELAY);
my $buf;

# bind a random TCP port for testing
my %lopts = (
    LocalAddr => "127.0.0.1",
    LocalPort => 0,
    Proto => "tcp",
    ReuseAddr => 1,
    Listen => 1024
);

my $srv = IO::Socket::INET->new(%lopts);
is ref($srv), "IO::Socket::INET";

my $chdb = HTTP::ClickHouse->new(host => $srv->sockhost, port => $srv->sockport, debug => 1);
is ref($chdb), "HTTP::ClickHouse";

is $chdb->{host}, $srv->sockhost;

is $chdb->{port}, $srv->sockport;

is $chdb->{nb_timeout}, 25;

is $chdb->{database}, 'default';

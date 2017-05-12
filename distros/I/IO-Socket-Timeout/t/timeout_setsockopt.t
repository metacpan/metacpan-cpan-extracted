use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use lib "$Bin/tlib";
use TestTimeout;
use Errno qw(ETIMEDOUT EWOULDBLOCK);
use Config;

my $osname = $Config{osname};
( $osname eq 'darwin' || $osname eq 'linux' )
  or plan skip_all => "Can't test setsockopt on this OS";


subtest 'test with no delays and no timeouts', sub {
TestTimeout->test( connection_delay => 0,
                   read_delay => 0,
                   write_delay => 0,
                   callback => sub {
                       my ($client) = @_;
                       $client->print("OK\n");
                       my $response = $client->getline;
                       is $response, "SOK\n", "got proper response 1";
                       $client->print("OK2\n");
                       $response = $client->getline;
                       is $response, "SOK2\n", "got proper response 2";
                   },
                 );
};

subtest 'test with sysread timeout', sub {
TestTimeout->test( connection_delay => 0,
                   read_timeout => 0.2,
                   read_delay => 3,
                   write_timeout => 0,
                   write_delay => 0,
                   callback => sub {
                       my ($client) = @_;
                       ok $client->isa('IO::Socket::Timeout::Role::SetSockOpt'),
                         'client does SetSockOpt';
                       $client->print("OK\n");
                       sysread $client, my $response, 4;
                       is $response, "SOK\n", "got proper response 1";
                       $client->print("OK2\n");
                       $response = undef;
                       ok ! ${*$client}{_invalid}, "socket is valid";
                       sysread $client, $response, 5;
                       is length($response || ''), 0, "we've hit timeout";
                       ok (0+$! == ETIMEDOUT || 0+$! == EWOULDBLOCK),
                         "and error is timeout or wouldblock";
                   },
                 );
};

done_testing;

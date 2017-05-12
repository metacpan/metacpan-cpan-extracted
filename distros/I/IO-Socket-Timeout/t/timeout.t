use strict;
use warnings;

BEGIN {
    $ENV{PERL_IO_SOCKET_TIMEOUT_FORCE_SELECT} = 1;
}

use Test::More;
use FindBin qw($Bin);
use lib "$Bin/tlib";
use TestTimeout;
use Errno qw(ETIMEDOUT);

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

subtest 'test with read timeout', sub {

TestTimeout->test( connection_delay => 0,
                   read_timeout => 0.2,
                   read_delay => 3,
                   write_timeout => 0,
                   write_delay => 0,
                   callback => sub {
                       my ($client) = @_;
                       ok $client->isa('IO::Socket::Timeout::Role::PerlIO'), 'client does PerlIO';
                       $client->print("OK\n");
                       my $response = $client->getline;
                       is $response, "SOK\n", "got proper response 1";
                       $client->print("OK2\n");
                       $response = $client->getline;
                       is $response, undef, "we've hit timeout";
                       is 0+$!, ETIMEDOUT, "and error is timeout";
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
                       ok $client->isa('IO::Socket::Timeout::Role::PerlIO'), 'client does PerlIO';
                       $client->print("OK\n");
                       sysread $client, my $response, 4;

                       is $response, "SOK\n", "got proper response 1";
                       $client->print("OK2\n");
                       $response = undef;
                       sysread $client, $response, 5;
                       is $response, undef, "we've hit timeout";
                       is 0+$!, ETIMEDOUT, "and error is timeout";
                   },
                 );
};

subtest 'test standard sysread/syswrite no timeout', sub {
TestTimeout->test( connection_delay => 0,
                   read_delay => 0,
                   write_delay => 0,
                   no_timeouts => 1,
                   callback => sub {
                       my ($client) = @_;
                       ok ! $client->isa('IO::Socket::Timeout::Role::PerlIO'), 'client does not do PerlIO';
                       $client->print("OK\n");
                       sysread $client, my $response, 4;

                       is $response, "SOK\n", "got proper response 1";
                       $client->print("OK2\n");
                       $response = undef;
                       sysread $client, $response, 5;
                       is $response, "SOK2\n", "got proper response 2";
                   },
                 );
};

done_testing;


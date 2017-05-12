package main;
use strict;
use warnings;

#--------------------------------------------------------------------------#
# requirements, fixtures and plan
#--------------------------------------------------------------------------#

use Test::More 0.74;
use Proc::Background 1.08;
use File::Spec 0.86;
use IO::CaptureOutput 1.06 qw/capture/;
use Probe::Perl 0.01;

# expected credentials for server and client
my $username = 'johndoe';
my $password = '123456';
my $port     = '31415';

# fire up the local mock server or skip tests
my $imapd = Proc::Background->new(
    { die_upon_destroy => 1 },
    Probe::Perl->find_perl_interpreter(),
    File::Spec->rel2abs( File::Spec->catfile(qw/t bin imapd.pl/) ),
    $port, $username, $password,
);

sleep 2; # give time for imapd to fire up and listen

unless ( $imapd && $imapd->alive ) {
    plan skip_all => "Couldn't launch mock imapd on localhost";
}

plan tests => 7;

my ( $stdout, $stderr, $rc );

#--------------------------------------------------------------------------#
# tests begin here
#--------------------------------------------------------------------------#

require_ok('Mail::Box::IMAP4::SSL');

ok( $imapd->alive, "mock imapd server is alive" );

my $imap;

$ENV{MAIL_BOX_IMAP4_SSL_NOVERIFY} = 1;

capture sub {
    $imap = Mail::Box::IMAP4::SSL->new(
        username    => $username,
        password    => $password,
        server_name => '127.0.0.1',
        server_port => $port,
    );
  } => \$stdout,
  \$stderr;

ok( $imap, "connected to mock imapd" );
is( $stderr, q{}, "No warnings during connection" );

capture sub { $rc = $imap->close } => \$stdout, \$stderr;

ok( $rc,                   "close() returned true value" );
ok( $imap->{MB_is_closed}, "internal close flag set" );
is( $stderr, q{}, "no warnings during close" );


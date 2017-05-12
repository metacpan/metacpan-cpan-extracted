#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;
use Test::Refcount;
use IO::Async::Test;
use IO::Async::Loop;

use IPC::PerlSSH::Async;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $ips = IPC::PerlSSH::Async->new(
   Command => "$^X",

   on_exception => sub { die "Perl died early - $_[0]" },
);

ok( defined $ips, "Constructor" );

is_oneref( $ips, '$ips has 1 refcount' );

$loop->add( $ips );

# Test basic eval / return
my $result;
$ips->eval( 
   code => '( 10 + 30 ) / 2',
   on_result => sub { $result = shift },
);

wait_for { defined $result };

is( $result, 20, "Scalar eval return" );

# Test list return
my @letters;
$ips->eval(
   code => 'split( m//, "Hello, world!" )',
   on_result => sub { @letters = @_ },
);

wait_for { @letters };

is_deeply( \@letters, [qw( H e l l o ), ",", " ", qw( w o r l d ! )], "List eval return" );

# Test argument passing
$ips->eval(
   code => 'join( ":", @_ )',
   args => [qw( some values here )],
   on_result => sub { $result = shift },
);

undef $result;
wait_for { defined $result };

is( $result, "some:values:here", "Scalar eval argument passing" );

# Test stored procedures
my $stored = 0;
$ips->store(
   name => 'add',
   code => 'my $t = 0; 
            while( defined( $_ = shift ) ) {
               $t += $_;
            }
            $t',
   on_stored => sub { $stored = 1 },
);

wait_for { $stored };

# Can't assert anything yet, but at least it didn't die

my $total;
$ips->call(
   name => 'add',
   args => [ 10, 20, 30, 40, 50 ],
   on_result => sub { $total = shift },
);

wait_for { defined $total };

is( $total, 150, "Stored procedure storing/invokation" );

$loop->remove( $ips );

is_oneref( $ips, '$ips has 1 refcount at EOF' );

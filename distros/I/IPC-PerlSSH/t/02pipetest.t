#!/usr/bin/perl -w

use strict;

use Test::More tests => 12;
use Test::Fatal;

use IPC::Open2;

use IPC::PerlSSH;

$SIG{ALRM} = sub {
   die "Alarm timeout exceeded\n";
};

alarm( 5 );

open2( my $readpipe, my $writepipe, $^X ) or die "Cannot open2 $^X - $!";

my $ips = IPC::PerlSSH->new( Readh => $readpipe, Writeh => $writepipe );
ok( defined $ips, "Constructor" );

alarm( 5 );

# Test basic eval / return
my $result = $ips->eval( '( 10 + 30 ) / 2' );
is( $result, 20, "Scalar eval return" );

alarm( 5 );

# Test list return
my @letters = $ips->eval( 'split( m//, "Hello, world!" )' );
is_deeply( \@letters, [qw( H e l l o ), ",", " ", qw( w o r l d ! )], "List eval return" );

alarm( 5 );

# Test argument passing
$result = $ips->eval( 'join( ":", @_ )', qw( some values here ) );
is( $result, "some:values:here", "Scalar eval argument passing" );

alarm( 5 );

# Test stored procedures
$ips->store( 'add', 'my $t = 0; 
                     while( defined( $_ = shift ) ) {
                        $t += $_;
                     }
                     $t' );

my $total = $ips->call( 'add', 10, 20, 30, 40, 50 );
is( $total, 150, "Stored procedure storing/invokation" );

alarm( 5 );

# Test caller binding
$ips->bind( 'dosomething', 'return "My string is $_[0]"' );
$result = dosomething( "hello" );
is( $result, "My string is hello", "Caller bound stored procedure" );

alarm( 5 );

# Test with $/ set to undef
$/ = undef;
$total = $ips->call( 'add', 1, 2 );
is( $total, 3, "Copes with nondefault \$/" );

# Storing a second time should fail
ok( exception { $ips->store( 'add', 'return 0' ) },
    "Storing a second time fails" );

alarm( 5 );

# Test that undef is representable
ok( !$ips->eval( 'defined $_[0]', undef ), 'Can send undef' );
ok( !defined $ips->eval( 'return undef' ), 'Can return undef' );

# Test with an arrayref for Command
$ips = IPC::PerlSSH->new( Command => [ "perl", "-w" ] );
ok( defined $ips, "Constructor with Command ARRAY" );

alarm( 5 );

# Test basic eval / return
$result = $ips->eval( '( 10 + 30 ) / 2' );
is( $result, 20, "Scalar eval return with Command ARRAY" );

alarm( 0 );

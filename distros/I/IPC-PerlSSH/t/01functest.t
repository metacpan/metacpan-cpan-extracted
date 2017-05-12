#!/usr/bin/perl -w

use strict;

use Test::More tests => 15;

use IPC::PerlSSH;

my $readbuffer;
sub readfunc
{
   if( !length $readbuffer ) {
      print STDERR "Ran out of read data\n";
      exit( 1 );
   }

   if( defined $_[1] ) {
      $_[0] = substr( $readbuffer, 0, $_[1], "" );
   }
   else {
      $readbuffer =~ s/^(.*\n)//;
      $_[0] = $1;
   }

   length $_[0];
}

my $writebuffer;
sub writefunc
{
   $writebuffer .= $_[0];
}

my $ips = IPC::PerlSSH->new( Readfunc => \&readfunc, Writefunc => \&writefunc );
ok( defined $ips, "Constructor" );

my $writeexpect;

# Test basic eval / return
$writeexpect = 
   "EVAL\n" .
   "1\n" .
   "15\n" . "( 10 + 30 ) / 2";
$readbuffer =
   "RETURNED\n" .
   "1\n" .
   "2\n" . "20";

$writebuffer = "";
my $result = $ips->eval( '( 10 + 30 ) / 2' );

is( $result, 20, "Scalar eval return" );
is( $writebuffer, $writeexpect, 'Write buffer is as expected' );
is( $readbuffer, "", 'Read buffer is now empty' );

# Test list return
$writeexpect = 
   "EVAL\n" .
   "1\n" .
   "29\n" . 'split( m//, "Hello, world!" )';
$readbuffer =
   "RETURNED\n" .
   "13\n" .
   "1\n" . "H" .
   "1\n" . "e" .
   "1\n" . "l" .
   "1\n" . "l" .
   "1\n" . "o" .
   "1\n" . "," .
   "1\n" . " " .
   "1\n" . "w" .
   "1\n" . "o" .
   "1\n" . "r" .
   "1\n" . "l" .
   "1\n" . "d" .
   "1\n" . "!";

$writebuffer = "";
my @letters = $ips->eval( 'split( m//, "Hello, world!" )' );

is_deeply( \@letters, [qw( H e l l o ), ",", " ", qw( w o r l d ! )], "List eval return" );
is( $writebuffer, $writeexpect, 'Write buffer is as expected' );
is( $readbuffer, "", 'Read buffer is now empty' );

# Test argument passing
$writeexpect =
   "EVAL\n" .
   "4\n" .
   "15\n" . 'join( ":", @_ )' .
   "4\n" . "some" .
   "6\n" . "values" .
   "4\n" . "here";
$readbuffer =
   "RETURNED\n" .
   "1\n" .
   "16\n" . "some:values:here";

$writebuffer = "";
$result = $ips->eval( 'join( ":", @_ )', qw( some values here ) );

is( $result, "some:values:here", "Scalar eval argument passing" );
is( $writebuffer, $writeexpect, 'Write buffer is as expected' );
is( $readbuffer, "", 'Read buffer is now empty' );

# Test stored procedures
$writeexpect =
   "STORE\n" .
   "2\n" .
   "3\n" . "add" .
   "146\n" . 'my $t = 0; 
                     while( defined( $_ = shift ) ) {
                        $t += $_;
                     }
                     $t';
$readbuffer =
   "OK\n" .
   "0\n";

$writebuffer = "";
$ips->store( 'add', 'my $t = 0; 
                     while( defined( $_ = shift ) ) {
                        $t += $_;
                     }
                     $t' );

is( $writebuffer, $writeexpect, 'Write buffer is as expected' );
is( $readbuffer, "", 'Read buffer is now empty' );

$writeexpect =
   "CALL\n" .
   "6\n" .
   "3\n" . "add" .
   "2\n" . "10" .
   "2\n" . "20" .
   "2\n" . "30" .
   "2\n" . "40" .
   "2\n" . "50";
$readbuffer =
   "RETURNED\n" .
   "1\n" .
   "3\n" . "150";

$writebuffer = "";
my $total = $ips->call( 'add', 10, 20, 30, 40, 50 );

is( $total, 150, "Stored procedure storing/invokation" );
is( $writebuffer, $writeexpect, 'Write buffer is as expected' );
is( $readbuffer, "", 'Read buffer is now empty' );

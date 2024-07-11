#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use IO::Termios;
use IO::Pty;

use POSIX qw( EAGAIN );

# Can't use STDIN as we don't know if it will be a TTY at testing time
my $pty = IO::Pty->new() or skip_all( "No PTY available" );

my $term = IO::Termios->new( $pty->slave );

# echo flag
{
   $term->setflag_echo( 1 );
   ok( $term->getflag_echo, '$term->getflag_echo is on' );

   $pty->syswrite( "With ECHO\n" );
   is( scalar <$term>, "With ECHO\n", '$term syswrite' );
   is( scalar <$pty>, "With ECHO\r\n", 'Echoed back' );

   $term->setflag_echo( 0 );
   ok( !$term->getflag_echo, '$term->getflag_echo is off' );
}

# non-blocking mode
{
   $pty->blocking( 0 );
   my $b;

   $pty->syswrite( "Without ECHO\n" );
   is( scalar <$term>, "Without ECHO\n", '$term syswrite' );
   ok( !defined $pty->sysread( $b, 8192 ), '$pty not readable' );
   is( $!+0, EAGAIN, '$pty not readable (EAGAIN)' );
}

# icanon flag
{
   $term->setflag_icanon( 0 );
   ok( !$term->getflag_icanon, '$term->getflag_icanon is off' );

   $term->blocking( 0 );

   my $rvec; my $rout;
   vec( $rvec, $term->fileno, 1 ) = 1;

   $pty->syswrite( "Without " );
   select( $rout = $rvec, undef, undef, 0.1 );
   ok( defined $term->sysread( $b, 8192 ), '$term is readable' );
   is( $b, "Without ", '$pty reads partial line' );
   $pty->syswrite( "ICANON\n" );
   select( $rout = $rvec, undef, undef, 0.1 );
   ok( defined $term->sysread( $b, 8192 ), '$term is readable' );
   is( $b, "ICANON\n", '$pty reads remainder of line' );

   $term->setflag_icanon( 1 );
   ok( $term->getflag_icanon, '$term->getflag_icanon is on' );

   $pty->syswrite( "With " );
   ok( !defined $term->sysread( $b, 8192 ), '$term not readable' );
   is( $!+0, EAGAIN, '$pty not readable (EAGAIN)' );
   $pty->syswrite( "ICANON\n" );
   select( $rout = $rvec, undef, undef, 0.1 );
   ok( defined $term->sysread( $b, 8192 ), '$term is readable' );
   is( $b, "With ICANON\n", '$pty reads remainder of line' );
}

# setflags wrapper
{
   $term->setflags(qw( +echo +cread -icrnl ));
   ok(  $term->getflag_echo, 'echo set after setflags +echo' );
   ok(  $term->getflag_cread, 'cread set after setflags +cread' );
   ok( !$term->getflag_icrnl, 'icrnl set after setflags -icrnl' );

   $term->setflags(qw( -echo +cread +icrnl ));
   ok( !$term->getflag_echo, 'echo set after setflags -echo' );
   ok(  $term->getflag_icrnl, 'icrnl set after setflags +icrnl' );
}

done_testing;

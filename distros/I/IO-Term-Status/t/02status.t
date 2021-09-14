#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::HexString;

use IO::Term::Status;

# It would be nice if I didn't have to do this...

my $written;
no warnings 'once';
*IO::Term::Status::print = sub { shift; $written .= join "", @_ };

my $h = IO::Term::Status->new;

{
   $written = "";
   $h->set_status( "status" );
   is_hexstr( $written, "\n\r\e[Kstatus\e[K\r\eM", '$written after ->set_status' );
}

# ->print_line with no partials
{
   $written = "";
   $h->print_line( "Hello, world" );
   is_hexstr( $written, "\n\r\e[K\eMHello, world\n\r\e[K\nstatus\e[K\r\eM" );

   $written = "";
   $h->print_line( "Another line" );
   is_hexstr( $written, "\n\r\e[K\eMAnother line\n\r\e[K\nstatus\e[K\r\eM" );
}

# partial updating
{
   $written = "";
   $h->more_partial( "He" );
   is_hexstr( $written, "He" );

   $written = "";
   $h->more_partial( "llo" );
   is_hexstr( $written, "llo" );

   $written = "";
   $h->finish_partial( ", world" );
   is_hexstr( $written, ", world\n\r\e[K\nstatus\e[K\r\eM" );
}

# partial with print_line
{
   $h->more_partial( "Hello" );

   $written = "";
   $h->print_line( "A full line here" );
   is_hexstr( $written, "\r\e[K\n\r\e[K\eMA full line here\n\r\e[K\nstatus\e[K\r\eMHello" );

   $written = "";
   $h->finish_partial( ", world" );
   is_hexstr( $written, ", world\n\r\e[K\nstatus\e[K\r\eM" );
}

# status can be changed
{
   $written = "";
   $h->set_status( "different status" );
   is_hexstr( $written, "\n\r\e[Kdifferent status\e[K\r\eM" );

   $written = "";
   $h->set_status( "" );
   is_hexstr( $written, "\n\r\e[K\r\eM" );
}

done_testing;

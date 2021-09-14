#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::HexString;

use IO::Term::Status;

my $written;
no warnings 'once';
*IO::Term::Status::print = sub { shift; $written .= join "", @_ };

my $h = IO::Term::Status->new;

# ->print_line with no partials
{
   $written = "";
   $h->print_line( "Hello, world" );
   is_hexstr( $written, "Hello, world\n", '$written after ->print_line' );
}

# partial updating
{
   $written = "";
   $h->more_partial( "Hello" );
   is_hexstr( $written, "Hello" );

   $written = "";
   $h->finish_partial( ", world" );
   is_hexstr( $written, ", world\n" . "\r\e[K" );
}

# partial replacement
{
   $h->more_partial( "Another line" );

   $written = "";
   $h->replace_partial( "Or not" );
   is_hexstr( $written, "\r\e[KOr not" );

   $h->finish_partial;
}

# partial with print_line
{
   $h->more_partial( "Hello" );

   $written = "";
   $h->print_line( "A full line here" );
   is_hexstr( $written, "A full line here\nHello" );

   $written = "";
   $h->finish_partial( ", world" );
   is_hexstr( $written, ", world\n" . "\r\e[K" );
}

done_testing;

#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::HexString;

eval { require String::Tagged::Terminal } or
   plan skip_all => "String::Tagged::Terminal is not available";

use IO::Term::Status;

# It would be nice if I didn't have to do this...

my $written;
no warnings 'once';
*IO::Term::Status::print = sub { shift; $written .= join "", @_ };

my $h = IO::Term::Status->new;

{
   $written = "";
   $h->set_status( String::Tagged->new
      ->append_tagged( "bold", bold => 1 )
      ->append_tagged( "reverse", reverse => 1 )
   );

   # A fragile test because we're depending on the SGR rendering form of
   # String::Tagged::Terminal, but there's not much else we can do here
   is_hexstr( $written, "\n\r\e[K" .
         "\e[1mbold\e[22;7mreverse\e[K\e[m" .
         "\r\eM",
      'status written using SGR formatting' );
}

done_testing;

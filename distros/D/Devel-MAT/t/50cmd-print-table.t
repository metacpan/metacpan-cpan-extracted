#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Devel::MAT;

sub lines_from(&)
{
   my ( $code ) = @_;

   my @lines;

   no warnings 'once';
   local *Devel::MAT::Cmd::printf = sub {
      shift;
      my ( $format, @args ) = @_;
      push @lines, sprintf $format, @args;
   };

   $code->();

   return join "", @lines;
}

# Basic table
{
   is( lines_from { Devel::MAT::Cmd->print_table( [ [ "A", "B", "C" ] ] ) },
       "A B C\n",
       'Single row' );

   is( lines_from { Devel::MAT::Cmd->print_table( [ [ "A", "B", "C" ], [ "De", "Fgh", "Ijkl" ] ] ) },
       "A  B   C\n" .
       "De Fgh Ijkl\n",
       'Rows are aligned' );
}

# Separator
{
   is( lines_from { Devel::MAT::Cmd->print_table( [ [ "A", "B", "C" ] ], sep => "," ) },
       "A,B,C\n",
       'Single row with separator' );
}

# Right alignment
{
   is( lines_from {
         Devel::MAT::Cmd->print_table( [ [ "A", 12, "C" ], [ "De", 3456, "Ijkl" ] ], align => [ undef, "right" ] );
      },
       "A    12 C\n" .
       "De 3456 Ijkl\n",
       'Rows are aligned' );
}

done_testing;

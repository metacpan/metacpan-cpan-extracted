#!/usr/bin/perl

use v5.14;
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

# Headings
{
   no warnings 'once';
   local *Devel::MAT::Cmd::format_heading = sub { return "*$_[1]*" };

   is( lines_from {
         Devel::MAT::Cmd->print_table( [ [ "1", "2" ] ], headings => [ "A", "B" ] ) },
      "*A* *B*\n" .
      "1   2\n",
      'Row with headings' );
}

# Indent
{
   is( lines_from {
         Devel::MAT::Cmd->print_table( [ [ "x", "y", "z" ] ], indent => 3 ) },
      "   x y z\n",
      'Row with indent' );
}

done_testing;

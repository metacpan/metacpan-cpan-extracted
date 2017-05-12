#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 9;
  chdir 't' if -d 't';
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  }

# import anything
use Devel::Size::Report qw/
  report_size track_size element_type
  entries_per_element
  /;

use Devel::Size qw/size total_size/;

my $x = 9; my $y = 18;

#############################################################################
# addresses

my $A = report_size( { foo => $x, bar => $y }, { addr => 1, } );

is ($A =~ /Hash ref\(0x[\da-fA-F]+\) /, 1, 'report contains address');

#############################################################################
# reference and scalar have different address

addr_are_different ( \"123", 2 );
addr_are_different ( \[123], 3 );
addr_are_different ( \{ foo => 1 }, 3 );

1;

#############################################################################
# subs

sub addr_are_different
  {
  my ($x,$c) = @_;

  $A = report_size( $x, { addr => 1, head => ''} );
  my @addr;

  $A =~ s/\(0x([\da-fA-F]+)\)/ push @addr, $1/eg;

  is (scalar @addr, $c, "contains $c addresses");
  is ($addr[0] ne $addr[1], 1, 'contains 2 different addresses');
  if ($c > 2)
    {
    is ($addr[0] ne $addr[2], 1, 'contains 3 different addresses');
    }
  }


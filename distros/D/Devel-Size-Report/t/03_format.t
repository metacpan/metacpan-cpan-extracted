#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 16;
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

my $x = "A string";
my $y = "A longer string";

#############################################################################
# formatting

my $A = report_size( qr/^(foo|bar)$/, { head => '', bytes => '' } );

is ( (scalar $A =~ /bytes/i) || 0, 0, 'No bytes text');

my $Z = report_size( $x );
like ($Z, qr/v$Devel::Size::Report::VERSION/, 'report contains version');
like ($Z, qr/Total: \d+ bytes/, 'report contains total sum');

$Z = report_size( { foo => $x, bar => $y }, { addr => 1, } );

like ($Z, qr/Hash ref\(0x[\da-fA-F]+\) /, 'report contains address');

#############################################################################
# multiple addresses, especially in sub-arrays and hash keys

$Z = report_size( [  [ 123, 321 ], \12 ], { addr => 1, } );
my $cnt = 0; $Z =~ s/\(0x[\da-fA-F]+\)/$cnt++/eg;

is ($cnt, 7, 'report contains 7 addresses');

$Z = report_size( [  { a => [ 123, 321 ], b => \12 } ], { addr => 1, } );
$cnt = 0; $Z =~ s/\(0x[\da-fA-F]+\)/$cnt++/eg;

is ($cnt, 8, 'report contains 8 addresses');

#############################################################################
# in regexps

$A = report_size( qr/^(foo|bar)$/, { head => '', addr => 1} );

like ($A, qr/\(0x[a-fA-F0-9]+\)/, 'Contains addr');

#############################################################################
# class names

$x = { foo => 0 }; bless $x, 'Foo';

$A = report_size( $x, { head => '', class => 1} );
like ( $A, qr/Hash ref \(Foo\)/, 'Contains (Foo)');

$y = [ bar => $x ]; bless $y, 'Bar';

$A = report_size( $y, { head => '', class => 1} );

like ( $A, qr/Hash ref \(Foo\)/, 'Contains (Foo)');
like ( $A, qr/Array ref \(Bar\)/, 'Contains (Bar)');

#############################################################################
# total with number of elements:

like ( $A, qr/Total.*4 elements/, 'Total: 4 elements');

#############################################################################
# summary

$A = report_size( $y, { summary => 1, head => '', class => 1 } );

like ($A, qr/1.*Foo/, 'one Foo');
like ($A, qr/1.*Bar/, 'one Bar');
like ($A, qr/2.*SCALAR/, 'two Scalar');

#############################################################################
# terse

$A = report_size( $y, { class => 1, terse => 1 } );

unlike ($A, qr/Foo/, "doesn't contain Foo");
like ($A, qr/Total:.*bytes in 4 elements/, "contains Total");


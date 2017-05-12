#!/usr/bin/perl -w

use strict;
BEGIN
  {
  use lib '../lib';
  chdir 'example' if -d 'example';
  }
use Devel::Size::Report qw(report_size);
use Scalar::Util qw/weaken/;

use IO::File;
use Math::BigFloat;

my $a = [ 8, 9, 7, [ 1,2,3, { a => 'b', size => 12.2, h => ['a'] }, 'rrr' ] ];

use Data::Dumper; print Dumper($a);

print report_size($a, { indend => "\t", left => '', total => undef,} ), "\n";

print report_size(Math::BigInt->new(1)),"\n";
print report_size(Math::BigFloat->new(1)),"\n";
print report_size(Math::BigFloat->new(1.2)),"\n";

my $FILE;
open($FILE, "size.pl") or die ("Cannot open size.pl: $!");
print report_size( $FILE, { total => '' } ), "\n";

print report_size( IO::File->new(), { total => '' } ), "\n";

print report_size( "a scalar", { total => '' } ), "\n";
print report_size( \"a scalar", {  } ), "\n";
my $x = \"a scalar"; weaken($x);
print report_size( $x, {  } ), "\n";

# these tw0 are actually different in size as Devel::Peek shows:
$a = [ 1,2 ];
print report_size( $a ), "\n";
my @a = (1,2);
print report_size( \@a ), "\n";

print report_size( sub { 3 < 5 ? 1 : 0; print "123"; 3; }), "\n";
$a = 1; my $code = sub { $a < 5 ? 1 : 0; print "123"; 3; };

print report_size( $code, { total => '' } ), "\n";

$x = [ 8 ]; my $y = [ $x, [ 1, $x ] ];
print report_size( $y ), "\n";

$x = [ 8 ]; $y = [ $x, [ 1, \8 ] ];
print report_size( $y ), "\n";

$x = "An LVALUE scalar";
print report_size( substr($x, 0, 9) ), "\n";

$x = v1.2.3;
print report_size( $x, { head => 'vstring v1.2.3' } ), "\n";


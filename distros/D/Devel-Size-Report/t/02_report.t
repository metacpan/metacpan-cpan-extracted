#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 43;
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
use Scalar::Util qw/weaken/;

my $x = "A string";
my $v = "V string";
my $y = "A much much longer string";	# should be at least 8 longer than $x for 64 bit!
my $z = "Some other long text here";	# length($z) == length($y)
my $elems = [ $x,$y,$z ];
my $nr = 123;
my $ref = \"1234";
my $vstring = v1.2.3;
my $ref_vstring = \v1.2.3;

my @size;

#############################################################################
# check that two reports with different things, but the same amount of them
# are equal 

# check that the report does not change the size!
my $old_size = total_size($x);
@size = track_size( $x );
is ($size[2], $old_size, "old size agrees with total_size");

my $Z = report_size( $x, { head => '' } );

is (total_size($x), $old_size, "still $old_size bytes");
is (total_size($x), size($x), "size() agrees with total_size()");

# looking twice shouldn't change anything
@size = track_size( $x );
is ($size[2], $old_size, "\$x is still $old_size bytes");
is (total_size($x), size($x), "size() agrees with total_size()");

# $v should be the same size than $x
@size = track_size( $v );
is ($size[2], $old_size, "\$v is still $old_size bytes");
is (total_size($v), size($v), "size() agrees with total_size()");
is (total_size($v), total_size($x), "\$x and \$v are the same sizes");

# XXX store size of $x
@size = track_size( $x );
is ($size[2], $old_size, "\$x is still $old_size bytes");
is (total_size($x), size($x), "size() agrees with total_size()");

my $A = report_size( $z, { head => '' } );
my $B = report_size( $y, { head => '' } );

is ($A, $B, 'two same-sized scalars reports are the same ');

@size = track_size( $x );
is ($size[2], $old_size, "\$x is still $old_size bytes");

@size = track_size( $v );
is ($size[2], $old_size, "\$v is still $old_size bytes");

is (total_size($x), size($x), "size() agrees with total_size()");

my $u = "A string";

my $C = report_size( $x, { head => '' } );
my $D = report_size( $x, { head => '' } );
my $E = report_size( $u, { head => '' } );

isnt ($A, $C, 'two different sized scalars reports are different');
isnt ($A, $E, 'two same-sized scalars reports are equal');
is ($C, $D, 'two different sized scalars reports are different');

my $code = sub { my $x = 129; $x = 12 if $x < 130; };

#############################################################################
# SCALAR 

$A = report_size( $nr, { head => '' } );
like ($A, qr/Scalar /, 'Scalar');
unlike ($A, qr/Read.Only/i, 'Not read only');

# read-only
$A = report_size( "1234", { head => '' } );
like ($A, qr/Read-Only Scalar /, 'Read-Only Scalar');

#############################################################################
# VSTRING

$A = report_size( v1.22.3, { head => '' } );

like ($A, qr/VString /, 'VString');
like ($A, qr/Read-Only VString /, 'RO VString');

$A = report_size( $vstring, { head => '' } );

like ($A, qr/VString /, 'VString');
unlike ($A, qr/Read-Only VString /, 'no RO VString');

# reference to a vstring

$A = report_size( $ref_vstring, { head => '' } );

if ($] < 5.010)
  {
  like ($A, qr/Scalar Ref /, 'Scalar Ref');
  like ($A, qr/Read-Only VString /, 'Read-Only VString');
  }
else
  {
  like ($A, qr/VString /, 'VString');
  like ($A, qr/in 1 elements/, '1 elements');
  }

#############################################################################
# HASH 

$A = report_size( { foo => "1234" }, { head => '' } );

like ($A, qr/Hash /, 'Hash');
like ($A, qr/'foo' =>/, 'Hash key is present');

#############################################################################
# ARRAY 

$A = report_size( [ 1, 2 ], { head => '' } );

like ($A, qr/Array /, 'Array');

#############################################################################
# SCALAR references

$A = report_size( \"1234", { head => '' } );
like ($A, qr/Scalar Ref/, 'Scalar ref');

weaken($ref);
$A = report_size( $ref, { head => '' } );
like ($A, qr/Weak Scalar Ref/, 'Weak Scalar ref');
unlike ($A, qr/Read-Only.*Scalar Ref/i, 'But not RO');
like ($A, qr/Read-Only Scalar/, 'RO Scalar');
unlike ($A, qr/Weak.*Scalar [^R]/i, 'RO Scalar');

#############################################################################
# ARRAY references

$A = report_size( \ [ 8, 9 ], { head => '' } );

like ($A, qr/Array ref Ref/, 'Array ref');

#############################################################################
# HASH references

$A = report_size( \ { a => 89 }, { head => '' } );

like ($A, qr/Hash ref Ref/, 'Hash ref');

#############################################################################
# CODE 

# see if this does something
my $CODE = report_size( $code, { head => '' } );

like ($CODE, qr/Code /, 'Contains code');

$CODE = report_size ( \&{'foo'}, { head => '' } );
like ($CODE, qr/Code /, 'Contains code');

#############################################################################
# STASH

$CODE = report_size ( \%::Devel::Size::Report::, { head => '' } );

like ($CODE, qr/report_size/, 'Contains report_size');

#############################################################################
# REGEXP

$A = report_size( qr/^(foo|bar)$/, { head => '' } );

like ($A, qr/Regexp/, 'Contains a regexp');

# COMMAND

$A = report_size( qx/echo/, { head => '' } );

like ($A, qr/Scalar/, 'Contains a scalar');

#############################################################################
# LVALUE

#use Devel::Peek; print Dump(substr($x,0,2));

$A = report_size( substr($x,0,2), { } );

#print "$A\n";

like ($A, qr/Scalar/, "Contains 'Scalar'");

#############################################################################
# GLOB

$A = report_size( \*STDIN, { } );

like ($A, qr/Glob/, "Contains 'Glob'");


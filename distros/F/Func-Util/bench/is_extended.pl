#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Scalar::Util qw(blessed looks_like_number);
use Func::Util qw(is_num is_int is_blessed is_scalar_ref is_regex is_glob);

print "=" x 60, "\n";
print "Extended Type Predicates Benchmark\n";
print "=" x 60, "\n\n";

my $num = 42.5;
my $int = 42;
my $str = "hello";
my $obj = bless {}, 'MyClass';
my $sref = \my $x;
my $regex = qr/foo/;

print "=== is_num ===\n";
cmpthese(-2, {
    'util::is_num'        => sub { is_num($num) },
    'looks_like_number'   => sub { looks_like_number($num) },
});

print "\n=== is_num (string) ===\n";
cmpthese(-2, {
    'util::is_num'        => sub { is_num($str) },
    'looks_like_number'   => sub { looks_like_number($str) },
});

print "\n=== is_int ===\n";
cmpthese(-2, {
    'util::is_int' => sub { is_int($int) },
    'pure_perl'    => sub { $int == int($int) },
});

print "\n=== is_blessed ===\n";
cmpthese(-2, {
    'util::is_blessed'   => sub { is_blessed($obj) },
    'Scalar::Util'       => sub { blessed($obj) ? 1 : 0 },
});

print "\n=== is_scalar_ref ===\n";
cmpthese(-2, {
    'util::is_scalar_ref' => sub { is_scalar_ref($sref) },
    'ref_eq_SCALAR'       => sub { ref($sref) eq 'SCALAR' },
});

print "\n=== is_regex ===\n";
cmpthese(-2, {
    'util::is_regex' => sub { is_regex($regex) },
    'ref_eq_Regexp'  => sub { ref($regex) eq 'Regexp' },
});

print "\nDONE\n";

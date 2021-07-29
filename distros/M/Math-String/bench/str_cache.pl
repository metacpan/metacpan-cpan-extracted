#!/usr/bin/perl -w

# benchmark to show the difference with and without caching in Math::String:
# v1.16 w/o cache, v1.20 w/ cache

$| = 1;
use lib shift || '../lib';
use Math::String;
use strict;
use Benchmark;

print "Math::String v$Math::String::VERSION\n\n";

my $set = Math::String::Charset->new( [ 'a' .. 'z' ]);

my $empty = Math::String->new('');
my $a = Math::String->new('a');
my $aa = Math::String->new('aa');
my $aaa = Math::String->new('aaa');

my ($x);

my $b = Math::String->new('', Math::String::Charset->new ( {
  sep => '-', start => [ 'foo', 'bar', 'baz' ],
  } ) );
my $d = Math::String->new('', Math::String::Charset->new ( {
  sep => '-', start => [ 'foo', 'bar', 'baz' ],
  } ) );

my $c = 'a';

my $z = Math::String->new('a'.'a' x 200);

my $z_u = $z->copy();
my $z_b = Math::String->new('b');

my $x_o = Math::String->new('a'.'a' x 100);

my $y = Math::BigInt->new(3);

my $num = Math::BigInt->new('12345678901234567890');

timethese ( -4, {
  'inc' => sub { $a++; $x = "$empty"; },
  'dec' => sub { $a--; $x = "$empty"; },
  'inc w/ sep' => sub { $b++; $x = "$b"; },
  'dec w/ sep' => sub { $d--; $x = "$d"; },
#  'build-in ++' => sub { $c++; $x = "$c"; },
  'new+bstr' => sub { my $u = Math::String->new('a' x 100); $x = "$u"; },
  'copy()' => sub { $z->copy(); },
  'bstr("a" x 200)' => sub { $x = "$z"; },
  'bstr("a")' => sub { $x = "$a"; },
  'bstr("aaa")' => sub { $x = "$aaa"; },
  'bstr("aaa") uncached' => sub { $aaa->{_cache} = undef; $x = "$aaa"; },
  'bstr() uncached' => sub { $z_u->{_cache} = undef; $x = "$z_u"; },
  'bstr("b") uncached' => sub { $z_b->{_cache} = undef; $x = "$z_b"; },
  'num2str(1234)' => sub { my $x = Math::String->from_number( 1234, $set ) },
  'num2str($num)' => sub { my $x = Math::String->from_number( $num, $set ) },
  'new("aaa")' => sub { my $x = Math::String->new( 'aaa', $set ) },
  'new("aaaaaa")' => sub { my $x = Math::String->new( 'aaaaaa', $set ) },
  'math' => sub {
    $x = $x_o->copy();
    $x = ($x * $y + $x + $x ** $y) / $y; },
  });

my $set_a_z = Math::String::Charset->new( [ 'a'..'z' ] );
my $set_0_9 = Math::String::Charset->new( [ '0'..'9' ] );

print "Benchmarking Math::String::Charset:\n\n";

timethese ( -5, {
  'new ( grouped )' => sub {
     my $set = Math::String::Charset->new( { sets => { 0 => $set_a_z, -1 => $set_0_9, 1 => $set_0_9 } } );
   },
  } );

timethese ( -5, {
  'new (a..z)' => sub {
     my $set = Math::String::Charset->new( [ 'a'..'z' ] );
   },
  'new (aa..zz)' => sub {
     my $set = Math::String::Charset->new( [ "aa" .. "zz" ] );
   },
  'copy (a..z)' => sub {
     my $set = $set_a_z->copy();
   },
  } );

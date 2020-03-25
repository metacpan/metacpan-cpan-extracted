#!./perl

use strict;
use warnings;
use Config; # to determine nvsize
use Test::More tests => 29;
use List::Uniqnum qw( uniqnum );
use B qw(svref_2object);
#use List::Util qw( uniqnum );


is_deeply( [ uniqnum qw( 1 1.0 1E0 2 3 ) ],
           [ 1, 2, 3 ],
           'uniqnum compares numbers' );

is_deeply( [ uniqnum qw( 1 1.1 1.2 1.3 ) ],
           [ 1, 1.1, 1.2, 1.3 ],
           'uniqnum distinguishes floats' );

{
    my @nums = map $_+0.1, 1e7..1e7+5;
    is_deeply( [ uniqnum @nums ],
               [ @nums ],
               'uniqnum distinguishes large floats' );

    my @strings = map "$_", @nums;
    is_deeply( [ uniqnum @strings ],
               [ @strings ],
               'uniqnum distinguishes large floats (stringified)' );
}

my ($uniq_count1, $uniq_count2, $equiv);

if($Config{nvsize} == 8) {
  # NV is either 'double' or 8-byte 'long double'

  # The 2 values should be unequal - but just in case perl is buggy:
  $equiv = 1 if 1.4142135623730951 == 1.4142135623730954;

  $uniq_count1 = uniqnum (1.4142135623730951,
                          1.4142135623730954 );

  $uniq_count2 = uniqnum('1.4142135623730951',
                         '1.4142135623730954' );
}

elsif(length(sqrt(2)) > 25) {
  # NV is either IEEE 'long double' or '__float128' or doubledouble

  if(1 + (2 ** -1074) != 1) {
    # NV is doubledouble

    # The 2 values should be unequal - but just in case perl is buggy:
    $equiv = 1 if 1 + (2 ** -1074) == 1 + (2 ** - 1073);

    $uniq_count1 = uniqnum (1 + (2 ** -1074),
                            1 + (2 ** -1073) );
    # The 2 values should be unequal - but just in case perl is buggy:
    $equiv = 1 if 4.0564819207303340847894502572035e31 == 4.0564819207303340847894502572034e31;

    $uniq_count2 = uniqnum('4.0564819207303340847894502572035e31',
                           '4.0564819207303340847894502572034e31' );
  }

  else {
    # NV is either IEEE 'long double' or '__float128'

    # The 2 values should be unequal - but just in case perl is buggy:
    $equiv = 1 if 1005.10228292019306452029161597769015 == 1005.1022829201930645202916159776901;

    $uniq_count1 = uniqnum (1005.10228292019306452029161597769015,
                            1005.1022829201930645202916159776901 );

    $uniq_count2 = uniqnum('1005.10228292019306452029161597769015',
                           '1005.1022829201930645202916159776901' );
  }
}

else {
  # NV is extended precision 'long double'

  # The 2 values should be unequal - but just in case perl is buggy:
  $equiv = 1 if 10.770329614269008063 == 10.7703296142690080625;

  $uniq_count1 = uniqnum (10.770329614269008063,
                          10.7703296142690080625 );

  $uniq_count2 = uniqnum('10.770329614269008063',
                         '10.7703296142690080625' );
}

if($equiv) {
  is($uniq_count1, 1, 'uniqnum preserves uniqueness of high precision floats');
  is($uniq_count2, 1, 'uniqnum preserves uniqueness of high precision floats (stringified)');
}

else {
  is($uniq_count1, 2, 'uniqnum preserves uniqueness of high precision floats');
  is($uniq_count2, 2, 'uniqnum preserves uniqueness of high precision floats (stringified)');
}

SKIP: {
    skip ('test not relevant for this perl configuration', 1) unless $Config{nvsize} == 8
                                                                  && $Config{ivsize} == 8;

    my @in = (~0, ~0 - 1, 18446744073709551614.0, 18014398509481985, 1.8014398509481985e16);
    my(@correct);

    # On perl-5.6.2 (and perhaps other old versions), ~0 - 1 is assigned to an NV.
    # This affects the outcome of the following test, so we need to first determine
    # whether ~0 - 1 is an NV or a UV:

    if("$in[1]" eq "1.84467440737096e+19") {

      # It's an NV and $in[2] is a duplicate of $in[1]
      @correct = (~0, ~0 - 1, 18014398509481985, 1.8014398509481985e16);
    }
    else {

      # No duplicates in @in
      @correct = @in;
    }

    is_deeply( [ uniqnum @in ],
               [ @correct ],
               'uniqnum correctly compares UV/IVs that overflow NVs' );
}

my $ls = 31;      # maximum left shift for 32-bit unity

if( $Config{ivsize} == 8 ) {
  $ls       = 63; # maximum left shift for 64-bit unity
}

# Populate @in with UV-NV pairs of equivalent values.
# Each of these values is exactly representable as 
# either a UV or an NV.

my @in = (1 << $ls, 2 ** $ls,
          1 << ($ls - 3), 2 ** ($ls - 3),
          5 << ($ls - 3), 5 * (2 ** ($ls - 3)));

my @correct = (1 << $ls, 1 << ($ls - 3), 5 << ($ls -3));

if( $Config{ivsize} == 8 && $Config{nvsize} == 8 ) {

     # Add some more UV-NV pairs of equivalent values.
     # Each of these values is exactly representable
     # as either a UV or an NV.

     push @in, ( 9007199254740991,     9.007199254740991e+15,
                 9007199254740992,     9.007199254740992e+15,
                 9223372036854774784,  9.223372036854774784e+18,
                 18446744073709549568, 1.8446744073709549568e+19,
                 18446744073709139968, 1.8446744073709139968e+19,
                 100000000000262144,   1.00000000000262144e+17,
                 100000000001310720,   1.0000000000131072e+17,
                 144115188075593728,   1.44115188075593728e+17,
                 -9007199254740991,     -9.007199254740991e+15,
                 -9007199254740992,     -9.007199254740992e+15,
                 -9223372036854774784,  -9.223372036854774784e+18,
                 -18446744073709549568, -1.8446744073709549568e+19,
                 -18446744073709139968, -1.8446744073709139968e+19,
                 -100000000000262144,   -1.00000000000262144e+17,
                 -100000000001310720,   -1.0000000000131072e+17,
                 -144115188075593728,   -1.44115188075593728e+17 );

     push @correct, ( 9007199254740991,
                      9007199254740992,
                      9223372036854774784,
                      18446744073709549568,
                      18446744073709139968,
                      100000000000262144,
                      100000000001310720,
                      144115188075593728,
                      -9007199254740991,
                      -9007199254740992,
                      -9223372036854774784,
                      -18446744073709549568,
                      -18446744073709139968,
                      -100000000000262144,
                      -100000000001310720,
                      -144115188075593728 );
}

# uniqnum should discard each of the NVs as being a
# duplicate of the preceding UV. 

is_deeply( [ uniqnum @in],
           [ @correct],
           'uniqnum correctly compares UV/IVs that don\'t overflow NVs' );

# Hard to know for sure what an Inf is going to be. Lets make one
my $Inf = 0 + 1E1000;
my $NaN;
$Inf **= 1000 while ( $NaN = $Inf - $Inf ) == $NaN;

is_deeply( [ uniqnum 0, 1, 12345, $Inf, -$Inf, $NaN, 0, $Inf, $NaN ],
           [ 0, 1, 12345, $Inf, -$Inf, $NaN ],
           'uniqnum preserves the special values of +-Inf and Nan' );

SKIP: {
    my $maxuint = ~0;
    my $maxint = ~0 >> 1;
    my $minint = -(~0 >> 1) - 1;

    my @nums = ($maxuint, $maxuint-1, -1, $maxint, $minint, 1 );

    {
        use warnings FATAL => 'numeric';
        if (eval {
            "$Inf" + 0 == $Inf
        }) {
            push @nums, $Inf;
        }
        if (eval {
            my $nanish = "$NaN" + 0;
            $nanish != 0 && !$nanish != $NaN;
        }) {
            push @nums, $NaN;
        }
    }

    is_deeply( [ uniqnum @nums, 1.0 ],
               [ @nums ],
               'uniqnum preserves uniqueness of full integer range' );

    my @strs = map "$_", @nums;

    if($maxuint !~ /\A[0-9]+\z/) {
      skip( "Perl $] doesn't stringify UV_MAX right ($maxuint)", 1 );
    }

    is_deeply( [ uniqnum @strs, "1.0" ],
               [ @strs ],
               'uniqnum preserves uniqueness of full integer range (stringified)' );
}

{
    my @nums = (6.82132005170133e-38, 62345678);
    is_deeply( [ uniqnum @nums ], [ @nums ],
        'uniqnum keeps uniqueness of numbers that stringify to the same byte pattern as a float'
    );
}

{
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

    is_deeply( [ uniqnum 0, undef ],
               [ 0 ],
               'uniqnum considers undef and zero equivalent' );

    ok( length $warnings, 'uniqnum on undef yields a warning' );

    is_deeply( [ uniqnum undef ],
               [ 0 ],
               'uniqnum on undef coerces to zero' );
}

is_deeply( [uniqnum 0, -0.0 ],
           [0],
           'uniqnum handles negative zero');


is( scalar( uniqnum qw( 1 2 3 4.5 5 ) ), 5, 'uniqnum() in scalar context' );

    "1 1 2" =~ m/(.) (.) (.)/;
    is_deeply( [ uniqnum $1, $2, $3 ],
               [ 1, 2 ],
               'uniqnum handles magic' );



{
    package Numify;

    use overload '0+' => sub { return $_[0]->{num} };

    sub new { bless { num => $_[1] }, $_[0] }

    package main;
    eval { require Scalar::Util;};

    if($@) { ok(1 == 1, 'skipping "uniqnum respects numify overload"') }
    else {
      my @nums = map { Numify->new( $_ ) } qw( 2 2 5 );

      # is_deeply wants to use eq overloading
      my @ret = uniqnum @nums;
      ok( scalar @ret == 2 &&
          Scalar::Util::refaddr($ret[0]) == Scalar::Util::refaddr($nums[0]) &&
          Scalar::Util::refaddr($ret[1]) == Scalar::Util::refaddr($nums[2]),
                 'uniqnum respects numify overload' );
   }
}

{
no warnings 'numeric';
my @in = (1 .. 5, 'a' .. 'z');

is_deeply( [ uniqnum (@in)],
           [ 1, 2, 3, 4, 5, 'a' ],
            'uniqnum uniquifies mixed numbers and strings as expected' );

my $count = uniqnum(@in);

cmp_ok($count, '==', 6, 'uniqnum uniquifies mixed numbers and strings as expected in scalar context');

@in = ('a' .. 'z', 1 .. 5);

is_deeply( [ uniqnum (@in)],
           [ 'a', 1, 2, 3, 4, 5],
            'uniqnum uniquifies mixed strings and numbers as expected' );

$count = uniqnum(@in);

cmp_ok($count, '==', 6, 'uniqnum uniquifies mixed strings and numbers as expected in scalar context');
}

SKIP: {
    skip ('test not relevant for this perl configuration', 4) unless $Config{ivsize} == 8;

  # 1e17 is the number beyond which "%.20g" formatting fails on some
  # 64-bit int perls - perhaps only on those built with a Microsoft compiler.
  # The following 2 tests check that the nearest values (both above
  # and below that tipping point) are being handled correctly.

  # 99999999999999984 is the largest 64-bit integer less than 1e17
  # that can be expressed exactly as a double

  is_deeply( [ uniqnum (99999999999999984, 99999999999999984.0) ],
             [ (99999999999999984) ],
             'uniqnum recognizes 99999999999999984 and 99999999999999984.0 as the same' );

  is_deeply( [ uniqnum (-99999999999999984, -99999999999999984.0) ],
             [ (-99999999999999984) ],
             'uniqnum recognizes -99999999999999984 and -99999999999999984.0 as the same' );

  # 100000000000000016 is the smallest positive 64-bit integer greater than 1e17
  # that can be expressed exactly as a double

  is_deeply( [ uniqnum (100000000000000016, 100000000000000016.0) ],
             [ (100000000000000016) ],
             'uniqnum recognizes 100000000000000016 and 100000000000000016.0 as the same' );

  is_deeply( [ uniqnum (-100000000000000016, -100000000000000016.0) ],
             [ (-100000000000000016) ],
             'uniqnum recognizes -100000000000000016 and -100000000000000016.0 as the same' );
}


@in = ( 17, -17, 2.3, -2.3, ~0, ~0 - 4, 1 << $ls, 1 << ($ls - 1), -(1 << ($ls - 1)),
        1 << ($ls - 8), -(1 << ($ls - 8)), 1 << ($ls - 13), -(1 << ($ls - 13)),
        (1 << ($ls - 1))  + 255, -(1 << ($ls - 1))  + 255,
        (1 << ($ls - 8))  + 255, -(1 << ($ls - 8))  + 255,
        (1 << ($ls - 13)) + 255, -(1 << ($ls - 13)) + 255,
        (2 ** 30) + 7.5, -(2 ** 30) + 7.5,
      );

my @incremented = ();

for(@in) { push @incremented, $_ + 1 }
{
  no warnings 'void';
  "$_" for @incremented; # add POK and pPOK flags to elements of @incremented;
}
push @in, @incremented;

my @pre_call  = map {svref_2object(\$_)->FLAGS} @in;
my @u = uniqnum(@in);
my @post_call = map {svref_2object(\$_)->FLAGS} @in;
my @u_flags = map {svref_2object(\$_)->FLAGS} @u;

  # uniqnum() can alter the numeric flags of a string argument. 
  # Don't worry about that as it's acceptable behaviour.
  # But check that the flags of uniqnum's numeric arguments
  # are not altered.

is_deeply( [ @pre_call  ],
           [ @post_call ],
           'uniqnum does not alter the flags of its numeric arguments' );

SKIP: {
    skip ("Perl's stringification of values is broken for this perl-5.6 configuration", 1) 
      if ( $] < 5.008 && $Config{ivsize} == $Config{nvsize} );
is_deeply( [@pre_call],
           [@u_flags],
           'uniqnum copies flags of numeric arguments to returned values' );
}

__END__


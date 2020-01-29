#!./perl

use strict;
use warnings;
use Config; # to determine nvsize
use Test::More tests => 23;
use List::Uniqnum qw( uniqnum );
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

my @in = (1 << $ls, 2 ** $ls,
          1 << ($ls - 3), 2 ** ($ls - 3),
          5 << ($ls - 3), 5 * (2 ** ($ls - 3)));

my @correct = (1 << $ls, 1 << ($ls - 3), 5 << ($ls -3));

if( $Config{ivsize} == 8 && $Config{nvsize} == 8 ) {
    my $p_53 = (1 << 53) - 1; # 9007199254740991

    # To obtain an NV, we need to first divide $p_53 by 2
    push @in, ($p_53 * 1024, $p_53/ 2 * 2048.0,
               $p_53 * 2048, $p_53 / 2 * 4096.0,
               ($p_53 -200) * 2048, ($p_53 - 200) / 2 * 4096.0);

    push @correct, ($p_53 * 1024, $p_53 * 2048, ($p_53 - 200) * 2048);
}

#my @x = uniqnum(@in);
#warn "\n\n @in\n\n @x\n\n @correct\n\n";

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
    use Scalar::Util qw( refaddr );

    my @nums = map { Numify->new( $_ ) } qw( 2 2 5 );

    # is_deeply wants to use eq overloading
    my @ret = uniqnum @nums;
    ok( scalar @ret == 2 &&
        refaddr $ret[0] == refaddr $nums[0] &&
        refaddr $ret[1] == refaddr $nums[2],
               'uniqnum respects numify overload' );
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

__END__

At time of writing this (27th Jan 2020), current version of List::Util is 1.53.
If, instead of using List::Uniqnum, you instead load List::Util at the beginning of this script, it's likely
you'll see the following errors with List-Util-1.53:

not ok 5 - uniqnum preserves uniqueness of high precision floats
#   Failed test 'uniqnum preserves uniqueness of high precision floats'
#   at 01uniqnum.t line 97.
#          got: '1'
#     expected: '2'
not ok 6 - uniqnum preserves uniqueness of high precision floats (stringified)
#   Failed test 'uniqnum preserves uniqueness of high precision floats (stringif
ied)'
#   at 01uniqnum.t line 98.
#          got: '1'
#     expected: '2'

This happens because List::Util::uniqnum regards the 2 distinct values provided by test 5 (and by test 6) as
being duplicates - even though they differ by 1 ULP.
(IIRC, some values that differ by more than 1 ULP can also be regarded as duplicates by List-Util-1.53)

The next failure you're likely to see is:

not ok 8 - uniqnum correctly compares UV/IVs that don't overflow NVs
#   Failed test 'uniqnum correctly compares UV/IVs that don't overflow NVs'
#   at 01uniqnum.t line 151.
#     Structures begin differing at:
#          $got->[1] = '9.22337203685478e+018'
#     $expected->[1] = '1152921504606846976'

(Values will differ depending upon $Config{nvsize})

Whereas tests 5 and 6 fail because unique values are regarded as duplicates, test 8 fails because duplicate
values are regarded as unique.
For example, the IV 1 << 63 is regarded as being different to the NV 2 ** 63.

Finally, expect test 16 to fail because 0.0 and -0.0 are deemed to be different values.

Expect extra test failures against older versions of List::Util.




#!/usr/bin/perl -w

# IMPORTANT NOTE:
#
# When testing total_size(), always remember that it dereferences things, so
# total_size([]) will NOT return the size of the ref + the array, it will only
# return the size of the array alone!

use Test::More;
use strict;
use Devel::SizeMe ':all';
use Devel::Peek;

my %types = (
    NULL => undef,
    IV => 42,
    RV => \1,
    NV => 3.14,
    PV => "Perl rocks",
    PVIV => do { my $a = 1; $a = "One"; $a },
    PVNV => do { my $a = 3.14; $a = "Mmm, pi"; $a },
    PVMG => do { my $a = $!; $a = "Bang!"; $a },
);

plan(tests => 19 + 4 * 12 + 2 * scalar keys %types);

#############################################################################
# verify that pointer sizes in array slots are sensible:
# create an array with 4 slots, 2 of them used
my $array = [ 1,2,3,4 ]; pop @$array; pop @$array;

# the total size minus the array itself minus two scalars is 4 slots
my $ptr_size = total_size($array) - total_size( [] ) - total_size(1) * 2;

is ($ptr_size % 4, 0, '4 pointers are dividable by 4');
isnt ($ptr_size, 0, '4 pointers are not zero');

# size of one slot ptr
$ptr_size /= 4;

#############################################################################
# assert hash and hash key size

# Note, undef puts PL_sv_undef on perl's stack. Assigning to a hash or array
# value is always copying, so { a => undef } has a value which is a fresh
# (allocated) SVt_NULL. Nowever, total_size(undef) isn't a copy, so total_size()
# sees PL_sv_undef, which is a singleton, interpreter wide, so isn't counted as
# part of the size. So we need to use an unassigned scalar to get the correct
# size for a SVt_NULL:
my $undef;

my $hash = {};
$hash->{a} = 1;
is (total_size($hash),
    total_size( { a => undef } ) + total_size(1) - total_size($undef),
    'assert hash and hash key size');

#############################################################################
# #24846 (Does not correctly recurse into references in a PVNV-type scalar)

# run the following tests with different sizes

for my $size (2, 3, 7, 100)
  {
  my $hash = { a => 1 };

  # hash + key minus the value
  my $hash_size = total_size($hash) - total_size(1);

  $hash->{a} = 0/1;
  $hash->{a} = [];

  my $pvnv_size = total_size(\$hash->{a}) - total_size([]);
  # size of one ref
  my $ref_size = total_size(\\1) - total_size(1);

  # $hash->{a} is now a PVNV, e.g. a scalar NV and a ref to an array:
#  SV = PVNV(0x81ff9a8) at 0x8170d48
#  REFCNT = 1
#  FLAGS = (ROK)
#  IV = 0
#  NV = 0
#  RV = 0x81717bc
#  SV = PVAV(0x8175d6c) at 0x81717bc
#    REFCNT = 1
#    FLAGS = ()
#    IV = 0
#    NV = 0
#    ARRAY = 0x0
#    FILL = -1
#    MAX = -1
#    ARYLEN = 0x0
#    FLAGS = (REAL)
#  PV = 0x81717bc ""
#  CUR = 0
#  LEN = 0

  # Compare this to a plain array ref
#SV = RV(0x81a2834) at 0x8207a2c
#  REFCNT = 1
#  FLAGS = (TEMP,ROK)
#  RV = 0x8170b44
#  SV = PVAV(0x8175d98) at 0x8170b44
#    REFCNT = 2
#    FLAGS = ()
#    IV = 0
#    NV = 0
#    ARRAY = 0x0
#    FILL = -1
#    MAX = -1
#    ARYLEN = 0x0

  # Get the size of the PVNV and the contained array
  my $element_size = total_size(\$hash->{a});

  cmp_ok($element_size, '<', total_size($hash), "element < hash with one element");
  cmp_ok($element_size, '>', total_size(\[]), "PVNV + [] > [] alone");

  # Dereferencing the PVNV (the argument to total_size) leaves us with
  # just the array, and this should be equal to a dereferenced array:
  is (total_size($hash->{a}), total_size([]), '[] vs. []');

  # the hash with one key
  # the PVNV in the hash
  # the RV inside the PVNV
  # the contents of the array (array size)

  my $full_hash = total_size($hash);
  my $array_size = total_size([]);
  is ($full_hash, $element_size + $hash_size, 'properly recurses into PVNV');
  is ($full_hash, $array_size + $pvnv_size + $hash_size, 'properly recurses into PVNV');

  $hash->{a} = [0..$size];

  # the outer references stripped away, so they should be the same
  is (total_size([0..$size]), total_size( $hash->{a} ), "hash element vs. array");

  # the outer references included, one is just a normal ref, while the other
  # is a PVNV, so they shouldn't be the same:
  isnt (total_size(\[0..$size]), total_size( \$hash->{a} ), "[0..size] vs PVNV");
  # and the plain ref should be smaller
  cmp_ok(total_size(\[0..$size]), '<', total_size( \$hash->{a} ), "[0..size] vs. PVNV");

  $full_hash = total_size($hash);
  $element_size = total_size(\$hash->{a});
  $array_size = total_size(\[0..$size]);

  print "# full_hash = $full_hash\n";
  print "# hash_size = $hash_size\n";
  print "# array size: $array_size\n";
  print "# element size: $element_size\n";
  print "# ref_size = $ref_size\n";
  print "# pvnv_size: $pvnv_size\n";

  # the total size is:

  # the hash with one key
  # the PVNV in the hash
  # the RV inside the PVNV
  # the contents of the array (array size)

  is ($full_hash, $element_size + $hash_size, 'properly recurses into PVNV');
#  is ($full_hash, $array_size + $pvnv_size + $hash_size, 'properly recurses into PVNV');

#############################################################################
# repeat the former test, but mix in some undef elements

  $array_size = total_size(\[0..$size, undef, undef]);

  $hash->{a} = [0..$size, undef, undef];
  $element_size = total_size(\$hash->{a});
  $full_hash = total_size($hash);

  print "# full_hash = $full_hash\n";
  print "# hash_size = $hash_size\n";
  print "# array size: $array_size\n";
  print "# element size: $element_size\n";
  print "# ref_size = $ref_size\n";
  print "# pvnv_size: $pvnv_size\n";

  is ($full_hash, $element_size + $hash_size, 'properly recurses into PVNV');

#############################################################################
# repeat the former test, but use a pre-extended array

  $array = [ 0..$size, undef, undef ]; pop @$array;

  $array_size = total_size($array);
  my $scalar_size = total_size(1) * (1+$size) + total_size($undef) * 1 + $ptr_size
    + $ptr_size * ($size + 2) + total_size([]);
  is ($scalar_size, $array_size, "computed right size if full array");

  $hash->{a} = [0..$size, undef, undef]; pop @{$hash->{a}};
  $full_hash = total_size($hash);
  $element_size = total_size(\$hash->{a});
  $array_size = total_size(\$array);

  print "# full_hash = $full_hash\n";
  print "# hash_size = $hash_size\n";
  print "# array size: $array_size\n";
  print "# element size: $element_size\n";
  print "# ref_size = $ref_size\n";
  print "# pvnv_size: $pvnv_size\n";

  is ($full_hash, $element_size + $hash_size, 'properly handles undef/non-undef inside arrays');

  } # end for different sizes

sub cmp_array_ro {
    my($got, $want, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is(@$got, @$want, "$desc (same element count)");
    my $i = @$want;
    while ($i--) {
	is($got->[$i], $want->[$i], "$desc (element $i)");
    }
}

{
    my $undef;
    my $undef_size = total_size($undef);
    cmp_ok($undef_size, '>', 0, 'non-zero size for NULL');

    my $iv_size = total_size(1);
    cmp_ok($iv_size, '>', 0, 'non-zero size for IV');

    # Force the array to allocate storage for elements.
    # This avoids making the assumption that just because it doesn't happen
    # initially now, it won't stay that way forever.
    my @array = 42;
    my $array_1_size = total_size(\@array);
    cmp_ok($array_1_size, '>', 0, 'non-zero size for array with 1 element');

    $array[2] = 6 * 9;

    my @copy = @array;

    # This might be making too many assumptions about the current implementation
    my $array_2_size = total_size(\@array);
    is($array_2_size, $array_1_size + $iv_size,
       "gaps in arrays don't allocate scalars");

    # Avoid using is_deeply() as that will read $#array, which is a write
    # action prior to 5.12. (Different writes on 5.10 and 5.8-and-earlier, but
    # a write either way, allocating memory.
    cmp_array_ro(\@array, \@copy, 'two arrays compare the same');

    # A write action:
    $array[1] = undef;

    is(total_size(\@array), $array_2_size + $undef_size,
       "assigning undef to a gap in an array allocates a scalar");

    cmp_array_ro(\@array, \@copy, 'two arrays compare the same');
}

{
    my %sizes;
    my $n = 1024; # not a constant to avoid constant folding
    # reverse sort ensures that PVIV, PVNV and RV are processed before
    # IV, NULL, or NV :-)
    foreach my $type (reverse sort keys %types) {
	# Need to make sure this goes in a new scalar every time. Putting it
	# directly in a lexical means that it's in the pad, and the pad recycles
	# scalars, a side effect of which is that they get upgraded in ways we
	# don't really want
	my $a;
	$a->[0] = $types{$type};
	undef $a->[0];

	my $expect = $sizes{$type} = size(\$a->[0]);

	$a->[0] = \('x' x $n);

	$expect = $sizes{RV} if $type eq 'NULL';
	$expect = $sizes{PVNV} if $type eq 'NV';
	$expect = $sizes{PVIV} if $type eq 'IV' && $] < 5.012;

	# Remember, size() removes a level of referencing if present. So add
	# one, so that we get the size of our reference:
	is(size(\$a->[0]), $expect,
	   "Type $type containing a reference, size() does not recurse to the referent");
	cmp_ok(total_size(\$a->[0]), '>', 1024,
	       "Type $type, total_size() recurses to the referent");
    }
}

{
    my $sub_size = total_size(\&cmp_array_ro);
    # 2941 from http://www.cpantesters.org/cpan/report/8c407bd8-cd37-11e2-8c80-50d7c5c10595 (5.18.0)
    # 2913 from http://www.cpantesters.org/cpan/report/4d809d28-d08a-11e2-93f8-c2ff5361878e (5.18.0)
    cmp_ok($sub_size, '>=', 2913, 'subroutine is at least a reasonable size');
    cmp_ok($sub_size, '<=', 51200, 'subroutine is no more than 50K')
	or diag 'Is total_size() dragging in the entire symbol table?';
    cmp_ok(total_size(\%::), '>=', 10240, 'symbol table is at least 100K');
}

# this test seems to assume a great deal and fails (7804>75759) with ref counting
#cmp_ok(total_size(\%Exporter::), '>', total_size(\%Exporter::Heavy::));

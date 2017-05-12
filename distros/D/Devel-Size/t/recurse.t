#!/usr/bin/perl -w

# IMPORTANT NOTE:
#
# When testing total_size(), always remember that it dereferences things, so
# total_size([]) will NOT return the size of the ref + the array, it will only
# return the size of the array alone!

use Test::More;
use strict;
use Devel::Size ':all';
use Config;

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

plan(tests => 20 + 4 * 12 + 2 * scalar keys %types);

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

	$a->[0] = \('x' x 1024);

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

# The intent of the following block of tests was to avoid repeating the
# potential regression if one changes how hashes are iterated. Specifically,
# commit f3cf7e20cc2a7a5a moves the iteration over hash values from total_size()
# to sv_size(). The final commit is complex, and somewhat a hack, as described
# in the comment in Size.xs above the definition of "NO_RECURSION".

# My original assumption was that the change (moving the iteration) was going to
# be simple, and look something like this:

=for a can of worms :-(

--- Size.xs	2015-03-20 21:00:31.000000000 +0100
+++ ../Devel-Size-messy/Size.xs	2015-03-20 20:51:19.000000000 +0100
@@ -615,6 +615,8 @@
               st->total_size += HEK_BASESIZE + cur_entry->hent_hek->hek_len + 2;
             }
           }
+          if (recurse)
+              sv_size(aTHX_ st, HeVAL(cur_entry), recurse);
           cur_entry = cur_entry->hent_next;
         }
       }
@@ -828,17 +830,6 @@
         }
       }
       TAG;break;
-
-    case SVt_PVHV: TAG;
-      dbg_printf(("# Found type HV\n"));
-      /* Is there anything in here? */
-      if (hv_iterinit((HV *)thing)) {
-        HE *temp_he;
-        while ((temp_he = hv_iternext((HV *)thing))) {
-          av_push(pending_array, hv_iterval((HV *)thing, temp_he));
-        }
-      }
-      TAG;break;
      
     case SVt_PVGV: TAG;
       dbg_printf(("# Found type GV\n"));

=cut

# nice and clean, removes 11 lines of special case clause for SVt_PVHV, adding
# only 2 into an existing loop.

# And it opened up a total can of worms. Existing tests failed because typeglobs
# in subroutines leading to symbol tables were now being followed, making
# reported sizes for subroutines now massively bigger.

# And it turned out (or seemed to be) that subroutines could even end up
# dragging in the entire symbol table in some cases. Hence a block of tests
# was added to verify that the reported size of &cmp_array_ro didn't explode as
# a result of this (or any further) refactoring.

# Obviously the patch above is broken, so it never got applied. But the test to
# prevent it *did*. Which was fine for 4 years. Except that it turns out that
# the test is actually sensitive to the size of Test::More::is() (because the
# subroutine cmp_array_ro() calls is()). And hence the test now *fails* because
# Test::More::is() got refactored.

# Which is a pain.
# So we get back to "what are we actually trying to test?"
# And really, the minimal thing that we were actually trying to test all along
# was *only* that a subroutine in a package with (other) imported subroutines
# doesn't get the size of their package rolled into it.
# Hence *this* is what the test should have been all along:

{
    package SWIT;
    use Test::More;
    sub sees_test_more {
        # This subroutine is in a package whose stash now contains typeglobs
        # which point to subroutines in Test::More. \%Test::More:: is rather
        # big, and we shouldn't be counting is size as part of the size of this
        # (empty!) subroutine.
    }
}

{
    # This used to be total_size(\&cmp_array_ro);
    my $sub_size = total_size(\&SWIT::sees_test_more);
    my $want = 1.5 + 0.125 * $Config{ptrsize};
    cmp_ok($sub_size, '>=', $want, "subroutine is at least ${want}K");
    cmp_ok($sub_size, '<=', 51200, 'subroutine is no more than 50K')
	or diag 'Is total_size() dragging in the entire symbol table?';
    cmp_ok(total_size(\%Test::More::), '>=', 102400,
           "Test::More's symbol table is at least 100K");
}

cmp_ok(total_size(\%Exporter::), '>', total_size(\%Exporter::Heavy::));

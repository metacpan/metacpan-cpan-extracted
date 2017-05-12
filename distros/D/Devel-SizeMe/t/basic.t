#!/usr/bin/perl -w

use Test::More;
use strict;
use Devel::SizeMe qw(size total_size);

#############################################################################
# some basic checks:

use vars qw($foo @foo %foo);
$foo = "12";
@foo = (1,2,3);
%foo = (a => 1, b => 2);

my $x = "A string";
my $y = "A much much longer string";        # need to be at least 7 bytes longer for 64 bit
cmp_ok(size($x), '<', size($y), 'size() of strings');
cmp_ok(total_size($x), '<', total_size($y), 'total_size() of strings');

my @x = (1..4);
my @y = (1..200);

my $size_1 = total_size(\@x);
my $size_2 = total_size(\@y);

cmp_ok($size_1, '<', $size_2, 'size() of array refs');

# the arrays alone shouldn't be the same size
$size_1 = size(\@x);
$size_2 = size(\@y);

isnt ( $size_1, $size_2, 'size() of array refs');

#############################################################################
# IV vs IV+PV (bug #17586)

$x = 12;
$y = 12; $y .= '';

$size_1 = size($x);
$size_2 = size($y);

cmp_ok($size_1, '<', $size_2, ' ."" makes string longer');

#############################################################################
# check that the tracking_hash is working

my($a,$b) = ([],[]);
my @ary1 = ($a, $a); # $a twice
my @ary2 = ($a, $b);
# remove the extra references held by the lexicals
undef $a;
undef $b;
cmp_ok(total_size(\@ary1), '<', total_size(\@ary2),
       'the tracking hash is working');

#############################################################################
# check that circular references don't mess things up

my($c1,$c2); $c2 = \$c1; $c1 = \$c2;

is (total_size($c1), total_size($c2), 'circular references');

##########################################################
# RT#14849 (& RT#26781 and possibly RT#29238?)
cmp_ok( total_size( sub{ do{ my $t=0 }; } ), '>', 0,
	'total_size( sub{ my $t=0 } ) > 0' );

# CPAN RT #58484 and #58485
cmp_ok(total_size(\&total_size), '>', 0, 'total_size(\&total_size) > 0');

use constant LARGE => 'N' x 8192;

cmp_ok (total_size(\&LARGE), '>', 8192,
        'total_size for a constant includes the constant');

{
    my $a = [];
    my $b = \$a;
    # Scalar::Util isn't in the core before 5.7.something.
    # The test isn't really testing anything without the weaken(), but it
    # isn't counter-productive or harmful to run it anyway.
    unless (eval {
	require Scalar::Util;
	# making a weakref upgrades the target to PVMG and adds magic
	Scalar::Util::weaken($b);
	1;
    }) {
	die $@ if $] >= 5.008;
    }

    is(total_size($a), total_size([]),
       'Any intial reference is dereferenced and discarded');
}

# Must call direct - avoid all copying:
foreach(['undef', total_size(undef)],
	['no', total_size(1 == 0)],
	['yes', total_size(1 == 1)],
       ) {
    my ($name, $size) = @$_;
    is($size, 0,
       "PL_sv_$name is interpeter wide, so not counted as part of the structure's size");
}

{
    # SvOOK stuff
    my $uurk = "Perl Rules";
    # This may upgrade the scalar:
    $uurk =~ s/Perl//;
    $uurk =~ s/^/Perl/;
    my $before_size = total_size($uurk);
    my $before_length = length $uurk;
    cmp_ok($before_size, '>', $before_length, 'Size before is sane');
    $uurk =~ s/Perl //;
    is(total_size($uurk), $before_size,
       "Size doesn't change because OOK is used");
    cmp_ok(length $uurk, '<', $before_size, 'but string is shorter');
}

sub shared_hash_keys {
    my %h = @_;
    my $one = total_size([keys %h]);
    cmp_ok($one, '>', 0, 'Size of one entry is sane');
    my $two =  total_size([keys %h, keys %h]);
    cmp_ok($two, '>', $one, 'Two take more space than one');
    my $increment = $two - $one;
    is(total_size([keys %h, keys %h, keys %h]), $one + 2 * $increment,
		 'Linear size increase for three');
    return $increment;
}

{
    my $small = shared_hash_keys(Perl => 'Rules');
    my $big = shared_hash_keys('x' x 1024, '');
 SKIP: {
	skip("[keys %h] doesn't copy as shared hash key scalars prior to 5.10.0",
	     1) if $] < 5.010;
	is ($small, $big, 'The "shared" part of shared hash keys is spotted');
    }
}

{
    use vars '%DANG_DANG_DANG_DANG_DANG_DANG_DANG_DANG_DANG';
    my $hash_size = total_size(\%DANG_DANG_DANG_DANG_DANG_DANG_DANG_DANG_DANG);
    cmp_ok($hash_size, '>', 0, 'Hash size is sane');
    my $stash_size
	= total_size(\%DANG_DANG_DANG_DANG_DANG_DANG_DANG_DANG_DANG::);
    cmp_ok($stash_size, '>',
	   $hash_size + length 'DANG_DANG_DANG_DANG_DANG_DANG_DANG_DANG_DANG',
	   'Stash size is larger than hash size plus length of the name');
}

{
    my %h = (Perl => 'Rules');
    my $hash_size = total_size(\%h);
    cmp_ok($hash_size, '>', 0, 'Hash size is sane');
    my $a = keys %h;
    if ($] < 5.010) {
	is(total_size(\%h), $hash_size,
	   "Creating iteration state doesn't need to allocate storage");
	# because all hashes carry the overhead of this storage from creation
    } else {
	cmp_ok(total_size(\%h), '>', $hash_size,
	       'Creating iteration state allocates storage');
    }
}

done_testing();

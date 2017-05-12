#!/usr/bin/perl -w

use strict;
use Test::More;

use Devel::SizeMe ':all';
use Config;
use Symbol;


my $warn_count;

$SIG{__WARN__} = sub {
    return if $_[0] =~ "Can't size up perlio layers yet\n";
    ++$warn_count;
    warn @_;
};

{
    my @array = (\undef, \undef, \undef);
    my $array_overhead = total_size(\@array);
    cmp_ok($array_overhead, '>', 0, 'Array has a positive size');

    my $real_gv_size = total_size(gensym());
    cmp_ok($real_gv_size, '>', 0, 'GVs have a positive size');

    # Eventually DonMartin gives up enough same-length names:
    $array[0] = gensym();   # \*PFLAP;

    my $with_one = total_size(\@array);
    is($with_one, $array_overhead + $real_gv_size,
       "agregate size is overhead ($array_overhead) plus GV ($real_gv_size)");

    $array[1] = gensym();   # \*CHOMP;

    my $with_two = total_size(\@array);
    cmp_ok($with_two, '>', $with_one, 'agregate size for 2 GVs is larger');
    # GvFILE may well be shared:
    cmp_ok($with_two, '<=', $with_one + $real_gv_size,
	   'agregate size for 2 GVs is not larger than overhead plus 2 GVs');

    my $incremental_gv_size = $with_two - $with_one;
    my $gv_shared = $real_gv_size - $incremental_gv_size;

    $array[2] = gensym();   # \*KSSSH;

    is(total_size(\@array), $with_one + 2 * $incremental_gv_size,
       "linear growth for 1, 2 and 3 GVs - $gv_shared bytes are shared");

    $array[2] = \undef;
    *{ $array[1] } = \*{ $array[0] }; #    *CHOMP = \*PFLAP;

    my $two_aliased = total_size(\@array);
    cmp_ok($two_aliased, '<', $with_two, 'Aliased typeglobs are smaller');

    my $gp_size = $with_two - $two_aliased;

    $array[2] = gensym();   # \*KSSSH;
    *{ $array[2] } = \*{ $array[0] };   # *KSSSH = \*PFLAP;
    is(total_size(\@array), $with_one + 2 * $incremental_gv_size - 2 * $gp_size,
       "3 aliased typeglobs are smaller, shared GP size is $gp_size");

TODO: {
    local $TODO = "rework for new recursion logic, if viable";

    my $copy = *{ $array[0] };  # *PFLAP;
    my $copy_gv_size = total_size($copy);
    # GV copies point back to the real GV through GvEGV. They share the same GP
    # and GvFILE. In 5.10 and later GvNAME is also shared.
    my $shared_gvname = 0;
    if ($] >= 5.010) {
	# Calculate the size of the shared HEK:
	my %h = (PFLAP => 0);
	my $shared = (keys %h)[0];
	$shared_gvname = total_size($shared);
	undef $shared;
	$shared_gvname-= total_size($shared);
    }
    is($copy_gv_size, $real_gv_size + $incremental_gv_size - $gp_size - $shared_gvname,
        'GV copies point back to the real GV');
   }

}

TODO: {
    local $TODO = "All remaining tests in t/globs.t skipped for now";
    fail();
}
done_testing();
exit 0;

# As of blead commit b50b20584a1bbc1a, Implement new 'use 5.xxx' plan,
# use strict; will write to %^H. In turn, this causes the eval $code below
# to have compile with a pp_hintseval with a private copy of %^H in the
# optree. In turn, this private value is copied on op execution and put on
# the stack. The act of copying requires a hash iterator, and the *first*
# time the op is encountered its private HV doesn't have space for one, so
# it's expanded to hold one. Which happens after $cv_was_size is assigned to.
# Which matters, because it means that the total size of anything that can
# reach \&gv_grew will include this extra size. In this case, this means that
# if the code for generate_glob() is within gv_grew() [as it used to be],
# then the generated subroutine's CvOUTSIDE points to an anon sub whose
# CvOUTSIDE points to gv_grew(). Which means that the generated subroutine
# gets "bigger" simply as a side effect of the eval executing.

# The solution is to put the eval that creates the subroutine into a different
# scope, so that its outside pointer chain doesn't include gv_grew(). Hence
# it's now broken out into generate_glob():

sub generate_glob {
    my ($sub, $glob) = @_;
    # unthreaded, this gives us a way of getting to sv_size() from one of the
    # other *_size() functions, with a GV that has nothing allocated from its
    # GP:
    eval "sub $sub { *$glob }; 1" or die $@;
}

sub gv_grew {
    my ($sub, $glob, $code, $type) = @_;

local $| = 1;
#local $Devel::Size::trace = 1;
#local $ENV{SIZEME}='/dev/tty';    

    diag "sub=$sub, glob=$glob, type=$type: $code";

    generate_glob($sub, $glob);
    # Assigning to IoFMT_GV() also provides this, threaded and unthreaded:
    $~ = $glob;

    is(do {no strict 'refs'; *{$glob}{$type}}, undef, "No reference for $type")
	unless $type eq 'SCALAR';
    my $cv_was_size = size(do {no strict 'refs'; \&$sub});
    diag "cv_was_size $cv_was_size";
    my $gv_was_size = size(do {no strict 'refs'; *$glob});
    diag "gv_was_size $gv_was_size";
    my $gv_was_total_size = total_size(do {no strict 'refs'; *$glob});
    diag "gv_was_total_size $gv_was_total_size";
    my $io_was_size = size(*STDOUT{IO});
    diag "io_was_size $io_was_size";

    eval $code or die "For $type, can't execute q{$code}: $@";
	
    my $new_thing = do {no strict 'refs'; *{$glob}{$type}};
    my $new_thing_size = size($new_thing);
    diag "new_thing_size $new_thing_size";

    my $cv_now_size = size(do {no strict 'refs'; \&$sub});
    diag "cv_now_size $cv_now_size (was $cv_was_size)";
    my $gv_now_size = size(do {no strict 'refs'; *$glob});
    diag "gv_now_size $gv_now_size (was $gv_was_size)";
    my $gv_now_total_size = total_size(do {no strict 'refs'; *$glob});
    diag "gv_now_total_size $gv_now_total_size (was $gv_was_total_size)";
    my $io_now_size = size(*STDOUT{IO});
    diag "io_now_size $io_now_size (was $io_was_size)";

    # These run string evals with the source file synthesised based on caller
    # source name, which means that %:: changes, which then peturbs sizes of
    # anything that can reach them. So calculate and record the sizes before
    # testing anything.
    isnt($new_thing, undef, "Created a reference for $type");
    cmp_ok($new_thing_size, '>', 0, "For $type, new item has a size");

    is($cv_now_size, $cv_was_size,
       "Under ithreads, the optree doesn't directly close onto a GV, so CVs won't change size")
	    if $Config{useithreads};
    if ($] < 5.010 && $type eq 'SCALAR') {
	is($cv_now_size, $cv_was_size, "CV doesn't grow as GV has SCALAR")
	    unless $Config{useithreads};
	is($io_now_size, $io_was_size, "IO doesn't grow as GV has SCALAR");
	is($gv_now_size, $gv_was_size, 'GV size unchanged as GV has SCALAR');
	is($gv_now_total_size, $gv_was_total_size,
	   'GV total size unchanged as GV has SCALAR');
    } elsif ($type eq 'CODE' || $type eq 'FORMAT') {
	# CV like things (effectively) close back over their typeglob, so its
	# hard to just get the size of the CV.
	cmp_ok($cv_now_size, '>', $cv_was_size, "CV grew for $type")
	    unless $Config{useithreads};
	cmp_ok($io_now_size, '>', $io_was_size, "IO grew for $type");
	# Assigning CVs and FORMATs to typeglobs causes the typeglob to get
	# weak reference magic
	cmp_ok($gv_now_size, '>', $gv_was_size, "GV size grew for $type");
	cmp_ok($gv_now_total_size, '>', $gv_was_total_size,
	       "GV total size grew for $type");
    } else {
	is($cv_now_size, $cv_was_size + $new_thing_size,
	   "CV grew by expected amount for $type")
	    	    unless $Config{useithreads};
	is($io_now_size, $io_was_size + $new_thing_size,
	   "IO total_size grew by expected amount for $type");
	is($gv_now_size, $gv_was_size + $new_thing_size,
	   "GV size grew by expected amount for $type");
	is($gv_now_total_size, $gv_was_total_size + $new_thing_size,
	   "GV total_size grew by expected amount for $type");
    }
    die 1;
}

gv_grew('glipp', 'zok', 'no strict "vars"; $zok = undef; 1', 'SCALAR');
gv_grew('bang', 'boff', 'no strict "vars"; @boff = (); 1', 'ARRAY');
gv_grew('clange', 'sock', 'no strict "vars"; %sock = (); 1', 'HASH');
SKIP: {
    skip("Can't create FORMAT references prior to 5.8.0", 7) if $] < 5.008;
    local $Devel::SizeMe::warn = 0;
    gv_grew('biff', 'zapeth', "format zapeth =\n.\n1", 'FORMAT');
}
gv_grew('crunch_eth', 'awkkkkkk', 'sub awkkkkkk {}; 1', 'CODE');

# Devel::SizeMe isn't even tracking PVIOs from GVs (yet)
# gv_grew('kapow', 'thwape', 'opendir *thwape, "."', 'IO');

is($warn_count, undef, 'No warnings emitted');

done_testing();

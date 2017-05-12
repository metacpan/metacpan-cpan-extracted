#!/usr/bin/perl -w

use strict;
use Test::More tests => 18;
use Devel::Size ':all';

# For me, for some files locally, I'm seeing failures
# Failed test '&two_lex is bigger than an empty sub by less than 2048 bytes'
# Just for some perl versions (5.8.7, 5.10.1, some 5.12.*)
# As ever, the reason is subtle and annoying. As this test is running in package
# main, loading modules at runtime might create entries in %::
# In this case, it's just one key, '_</.../lib/perl5/5.12.4/overload.pm'
# because Test::More is demand loading overload at the first test.
# So the first fix I tried was to "encourage" Test::More to get all this done
# before we start doing things that are sensitive to the size of %::
# with this:
#
# cmp_ok(1, '==', 1, "prompt Test::More to load everything it needs *now*");
#
# which fixed most things, but not 5.8.7, which (*only under make test*) would
# fail '&two_lex is bigger than an empty sub by less than 2048 bytes'
# Turns out that Test::More 0.54 creates an entry in %:: for every test run
# (not sure why, side effect of an eval with a #line directive, maybe?)
# The solution is to measure (and re-measure) the size of things you're
# comparing as contiguous statements, assigning to variables, and then make
# calls to Test::More functions.

sub zwapp;
sub swoosh($$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$);
sub crunch {
}

my $whack_size = total_size(\&whack);
my $zwapp_size = total_size(\&zwapp);
my $swoosh_size = total_size(\&swoosh);
my $crunch_size = total_size(\&crunch);

cmp_ok($whack_size, '>', 0, 'CV generated at runtime has a size');
if("$]" >= 5.017) {
    cmp_ok($zwapp_size, '==', $whack_size,
	   'CV stubbed at compiletime is the same size');
} else {
    cmp_ok($zwapp_size, '>', $whack_size,
	   'CV stubbed at compiletime is larger (CvOUTSIDE is set and followed)');
}
cmp_ok(length prototype \&swoosh, '>', 0, 'prototype has a length');
cmp_ok($swoosh_size, '>', $zwapp_size + length prototype \&swoosh,
       'prototypes add to the size');
cmp_ok($crunch_size, '>', $zwapp_size, 'sub bodies add to the size');

my $anon_proto = sub ($$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$) {};
my $anon_size = total_size(sub {});
my $anon_proto_size = total_size($anon_proto);
cmp_ok($anon_size, '>', 0, 'anonymous subroutines have a size');
cmp_ok(length prototype $anon_proto, '>', 0, 'prototype has a length');
cmp_ok($anon_proto_size, '>', $anon_size + length prototype $anon_proto,
       'prototypes add to the size');

SKIP: {
    use vars '@b';
    my $aelemfast_lex = total_size(sub {my @a; $a[0]});
    my $aelemfast = total_size(sub {my @a; $b[0]});

    # This one is sane even before Dave's lexical aelemfast changes:
    cmp_ok($aelemfast_lex, '>', $anon_size,
	   'aelemfast for a lexical is handled correctly');
    skip('alemfast was extended to lexicals after this perl was released', 1)
      if $] < 5.008004;
    cmp_ok($aelemfast, '>', $aelemfast_lex,
	   'aelemfast for a package variable is larger');
}

my $short_pvop = total_size(sub {goto GLIT});
my $long_pvop = total_size(sub {goto KREEK_KREEK_CLANK_CLANK});
cmp_ok($short_pvop, '>', $anon_size, 'OPc_PVOP can be measured');
is($long_pvop, $short_pvop + 19, 'the only size difference is the label length');

sub bloop {
    my $clunk = shift;
    if (--$clunk > 0) {
	bloop($clunk);
    }
}

my $before_size = total_size(\&bloop);
bloop(42);
my $after_size = total_size(\&bloop);

cmp_ok($after_size, '>', $before_size, 'Recursion increases the PADLIST');

sub closure_with_eval {
    my $a;
    return sub { eval ""; $a };
}

sub closure_without_eval {
    my $a;
    return sub { require ""; $a };
}

if ($] > 5.017001) {
    # Again relying too much on the core's implementation, but while that holds,
    # this does test that CvOUTSIDE() is being followed.
    cmp_ok(total_size(closure_with_eval()), '>',
	   total_size(closure_without_eval()) + 256,
	   'CvOUTSIDE is now NULL on cloned closures, unless they have eval');
} else {
    # Seems that they differ by a few bytes on 5.8.x
    cmp_ok(total_size(closure_with_eval()), '<=',
	   total_size(closure_without_eval()) + 256,
	   "CvOUTSIDE is set on all cloned closures, so these won't differ by much");
}

sub two_lex {
    my $a;
    my $b;
}

sub ode {
    my $We_are_the_music_makers_And_we_are_the_dreamers_of_dreams_Wandering_by_lone_sea_breakers_And_sitting_by_desolate_streams_World_losers_and_world_forsakers_On_whom_the_pale_moon_gleams_Yet_we_are_the_movers_and_shakers_Of_the_world_for_ever_it_seems;
    my $With_wonderful_deathless_ditties_We_build_up_the_world_s_great_cities_And_out_of_a_fabulous_story_We_fashion_an_empire_s_glory_One_man_with_a_dream_at_pleasure_Shall_go_forth_and_conquer_a_crown_And_three_with_a_new_song_s_measure;
    # /Ode/, Arthur O'Shaughnessy, published in 1873.
    # Sadly all but one of the remaining versus are too long for an identifier.
}

# Aargh, re-measure it. See comment at the top of the file.
$crunch_size = total_size(\&crunch);
my $two_lex_size = total_size(\&two_lex);
cmp_ok($two_lex_size, '>', $crunch_size,
       '&two_lex is bigger than an empty sub');
cmp_ok($two_lex_size, '<', $crunch_size + 2048,
       '&two_lex is bigger than an empty sub by less than 2048 bytes');

my $ode_size = total_size(\&ode);
{
    # Fixing this for pre-v5.18 involves solving the more general problem of
    # when to "recurse" into nested structures, currently bodged with
    # "SOME_RECURSION" and friends. :-(
    local $::TODO =
        'Devel::Size has never handled the size of names in the pad correctly'
        if $] < 5.017004;
    cmp_ok($ode_size, '>', $two_lex_size + 384,
           '&ode is bigger than a sub with two lexicals by least 384 bytes');
}

cmp_ok($ode_size, '<', $two_lex_size + 768,
       '&ode is bigger than a sub with two lexicals by less than 768 bytes');

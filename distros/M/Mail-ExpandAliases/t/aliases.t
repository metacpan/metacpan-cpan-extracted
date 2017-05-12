#!/usr/bin/perl -w
# ----------------------------------------------------------------------
# vim: set ft=perl:
# ----------------------------------------------------------------------
# All email addresses in this file go to unresolvable.perl.org, which
# I think I made up.  My apologies to Tom, Barnaby, Bridget, and Quincy
# if you get mail at these addresses.
# ----------------------------------------------------------------------

use strict;
use FindBin qw($Bin);
use Mail::ExpandAliases;
use File::Spec::Functions qw(catfile);
use Test::More;

my ($aliases_file, $m, @a, $a);
BEGIN {
    plan tests => 15;
}

use_ok("Mail::ExpandAliases");

$aliases_file = catfile($Bin, "aliases");

ok(defined($m = Mail::ExpandAliases->new($aliases_file)));

@a = $m->expand('spam');
is($a[0], '/dev/null', "'spam' => '$a[0]'");
undef @a;

# Lists of addresses are sorted
@a = $m->expand('jones');
$a = join ',', @a;
is($a, 'Barnaby_Jones@unresolvable.perl.org,Bridget_Jones@unresolvable.perl.org,Quincy_Jones@unresolvable.perl.org,Tom_Jones@unresolvable.perl.org', "'jones' => '$a'");
undef @a;

# Standard MAILER-DAEMON expansion test
@a = $m->expand('MAILER-DAEMON');
is($a[0], '/dev/null', "'MAILER-DAEMON' => '$a[0]'");
undef @a;

# An alias that is not in the file; should "expand" to itself.
@a = $m->expand('not-there');
is($a[0], 'not-there', "'not-there' => '$a[0]'");
undef @a;

# Just a regular alias (see next test for why this one is here)
@a = $m->expand('tjones');
is($a[0], 'Tom_Jones@unresolvable.perl.org', "'tjones' => '$a[0]'");
undef @a;

# Different capitalization of the above alias -- they should return
# the same value.
@a = $m->expand('TJones');
is($a[0], 'Tom_Jones@unresolvable.perl.org', "'TJones' => '$a[0]'");
undef @a;

# Another pair of capitilization tests
@a = $m->expand('postmaster');
is($a[0], '/dev/null', "'postmaster' => '$a[0]'");
undef @a;

@a = $m->expand('Postmaster');
is($a[0], '/dev/null', "'Postmaster' => '$a[0]'");
undef @a;


# Expands to a command.
@a = $m->expand("redist");
is($a[0], '| /path/to/redist', "'redist' => '$a[0]'");
undef @a;

# Expands to a path
@a = $m->expand("archive");
is($a[0], '/var/mail/archive', "'redist' => '$a[0]'");
undef @a;

# Backslashed alias:
# backslashed: \jones
# Note that jones is another alias in this file; the backslash
# should prevent it from being further expanded.
@a = $m->expand("backslashed");
is($a[0], "jones", "'backslashed' => '$a[0]'");
undef @a;

# Self-referential alias:
# nothing: nothing
@a = $m->expand("nothing");
is($a[0], "nothing", "'nothing' => '$a[0]'");
undef @a;

@a = $m->expand("silly");
$a = join ",", @a;
is($a, "silly,stuff", "'silly' => '$a'");
undef @a;


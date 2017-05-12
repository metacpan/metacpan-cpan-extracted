#!/usr/bin/perl -w

use strict;
my ($numtests, $loaded);

BEGIN { $numtests = 76; $| = 1; print "1..$numtests\n"; } # FIXME
END {print "not ok 1\n" unless $loaded;}
use Lingua::Preferred qw(which_lang acceptable_lang);
$loaded = 1;
print "ok 1\n";

use Data::Dumper;

my $tests_done = 1;
sub check_which_lang( $$$ ) {
    my ($want, $avail, $ans) = @_;
    my $got = Dumper(which_lang($want, $avail));
    if ($got ne Dumper($ans)) {
	warn "wanted: @$want\navailable: @$avail\nexpected: $ans\ngot: $got";
	print 'not ';
    }
    print 'ok ', ++$tests_done, "\n";
}

check_which_lang [                             ], [ 'en'                   ], 'en';
check_which_lang [                             ], [ undef                  ], undef;
check_which_lang [ 'fr'                        ], [ 'en'                   ], 'en';
check_which_lang [ 'fr'                        ], [ 'en', 'fr'             ], 'fr';
check_which_lang [ 'fr'                        ], [ 'en', 'fr_FR'          ], 'fr_FR';
check_which_lang [ 'fr'                        ], [ 'en', 'fr_FR', 'fr'    ], 'fr';
check_which_lang [ 'fr'                        ], [ undef                  ], undef;
check_which_lang [ 'fr', 'en'                  ], [ 'fr'                   ], 'fr';
check_which_lang [ 'fr', 'en'                  ], [ 'en'                   ], 'en';
check_which_lang [ 'fr', 'en'                  ], [ 'de'                   ], 'de';
check_which_lang [ 'fr', 'en'                  ], [ 'de', 'it'             ], 'de';
check_which_lang [ 'fr', 'en'                  ], [ undef                  ], undef;
check_which_lang [ 'en_GB'                     ], [ 'en'                   ], 'en';
check_which_lang [ 'en_GB'                     ], [ 'fr'                   ], 'fr';
check_which_lang [ 'en_GB'                     ], [ undef                  ], undef;
check_which_lang [ 'en_GB'                     ], [ 'en_US'                ], 'en_US';
check_which_lang [ 'en_GB'                     ], [ 'en_US', 'en_IT'       ], 'en_US';
check_which_lang [ 'en_GB'                     ], [ 'en_US', 'en'          ], 'en';
check_which_lang [ 'en_GB'                     ], [ 'en_US', 'en', 'en_GB' ], 'en_GB';
check_which_lang [ 'en', 'en_GB'               ], [ 'en_US'                ], 'en_US';
check_which_lang [ 'en', 'en_GB'               ], [ 'en_IT', 'en_GB'       ], 'en_GB';
check_which_lang [ 'en', 'en_GB'               ], [ 'en', 'en_GB'          ], 'en';
check_which_lang [ 'en_GB', 'en'               ], [ 'en', 'en_GB'          ], 'en_GB';
check_which_lang [ 'de', 'de_*', 'de_CH'       ], [ 'fr'                   ], 'fr';
check_which_lang [ 'de', 'de_*', 'de_CH'       ], [ 'de_CH'                ], 'de_CH';
check_which_lang [ 'de', 'de_*', 'de_CH'       ], [ 'de_CH', 'de_DE'       ], 'de_DE';
check_which_lang [ 'de', 'de_*', 'fr', 'de_CH' ], [ 'de_CH', 'fr'          ], 'fr';
# C matches anything, but it need not be first in the list
check_which_lang [ 'C',                        ], [ 'en'                   ], 'en';
check_which_lang [ 'C',                        ], [ undef                  ], undef;
check_which_lang [ 'en', 'C',                  ], [ 'en'                   ], 'en';
check_which_lang [ 'C', 'en',                  ], [ 'en'                   ], 'en';
check_which_lang [ 'C'                         ], [ 'en', 'fr'             ], 'en';
check_which_lang [ 'C', 'fr'                   ], [ 'en', 'fr'             ], 'en';
check_which_lang [ 'fr', 'C'                   ], [ 'en', 'fr'             ], 'fr';
# The following are probably not something you'd actually use
check_which_lang [ 'en_*'                      ], [ 'en_GB', 'fr'          ], 'en_GB';
# N.B. en_* implies en_IE, en_CA etc. but not en
check_which_lang [ 'en_*'                      ], [ 'fr', 'en'             ], 'fr';
check_which_lang [ 'en_*'                      ], [ undef                  ], undef;
check_which_lang [ 'de_*', 'de_CH'             ], [ 'de_CH', 'de', 'de_DE' ], 'de_DE';
check_which_lang [ 'de', 'fr', 'de_*', 'de_CH' ], [ 'de_CH', 'de_AT', 'fr' ], 'fr';

sub check_acceptable_lang( $$$ ) {
    my ($want, $l, $ans) = @_;
    my $got = acceptable_lang($want, $l);
    if ($got != $ans) {
	warn "wanted: @$want\nlang: $l\nexpected: $ans\ngot: $got";
	print 'not ';
    }
    print 'ok ', ++$tests_done, "\n";
}

check_acceptable_lang [                             ], 'en',    0;
check_acceptable_lang [ 'fr'                        ], 'en',    0;
check_acceptable_lang [ 'fr'                        ], 'en_ZA', 0;
check_acceptable_lang [ 'fr'                        ], 'fr',    1;
check_acceptable_lang [ 'fr'                        ], 'fr_FR', 1;
check_acceptable_lang [ 'fr', 'en'                  ], 'fr',    1;
check_acceptable_lang [ 'fr', 'en'                  ], 'en',    1;
check_acceptable_lang [ 'fr', 'en'                  ], 'de',    0;
check_acceptable_lang [ 'fr', 'en'                  ], 'fr_FR', 1;
check_acceptable_lang [ 'fr', 'en'                  ], 'en_FR', 1; # why not?
check_acceptable_lang [ 'fr', 'en'                  ], 'it_CH', 0;
check_acceptable_lang [ 'en_GB'                     ], 'en',    1;
check_acceptable_lang [ 'en_GB'                     ], 'en_GB', 1;
check_acceptable_lang [ 'en_GB'                     ], 'en_CA', 1;
check_acceptable_lang [ 'en_GB'                     ], 'nl',    0;
check_acceptable_lang [ 'en_GB'                     ], 'nl_NL', 0;
check_acceptable_lang [ 'en', 'en_GB'               ], 'en',    1;
check_acceptable_lang [ 'en', 'en_GB'               ], 'en_GB', 1;
check_acceptable_lang [ 'en', 'en_GB'               ], 'en_CA', 1;
check_acceptable_lang [ 'en', 'en_GB'               ], 'nl',    0;
check_acceptable_lang [ 'en', 'en_GB'               ], 'nl_NL', 0;
check_acceptable_lang [ 'en_IE', 'en_US'            ], 'en',    1;
check_acceptable_lang [ 'en_IE', 'en_US'            ], 'en_GB', 1;
check_acceptable_lang [ 'en_IE', 'en_US'            ], 'en_CA', 1;
check_acceptable_lang [ 'en_IE', 'en_US'            ], 'nl',    0;
check_acceptable_lang [ 'en_IE', 'en_US'            ], 'nl_NL', 0;
check_acceptable_lang [ 'de', 'de_*', 'de_CH'       ], 'fr',    0;
check_acceptable_lang [ 'de', 'de_*', 'de_CH'       ], 'de',    1;
check_acceptable_lang [ 'de', 'de_*', 'de_CH'       ], 'de_DE', 1;
check_acceptable_lang [ 'de', 'de_*', 'de_CH'       ], 'de_CH', 1;
# The following are probably not something you'd actually use
check_acceptable_lang [ 'en_*'                      ], 'en_GB', 1;
check_acceptable_lang [ 'en_*'                      ], 'it',    0;
check_acceptable_lang [ 'en_*'                      ], 'en',    1;
check_acceptable_lang [ 'de', 'fr', 'de_*', 'de_CH' ], 'fr',    1;
check_acceptable_lang [ 'de', 'fr', 'de_*', 'de_CH' ], 'nl',    0;
check_acceptable_lang [ 'de', 'fr', 'de_*', 'de_CH' ], 'de_CH', 1;

if ($tests_done != $numtests) {
    die "expected to run $numtests tests, but ran $tests_done\n";
}

__END__

# Stuff for randomly generating test cases.  I didn't really use this.
my @l = qw(en en_GB en_US de de_DE de_AT de_CH fr fr_FR fr_CA it it_IT);
my @l2 = qw(en_* fr_* de_* it_*);

sub randomize(@) {
    my @r;
    push @r, splice(@_, (rand @_), 1) while @_;
    @r;
}
sub random_prefix(@) { @_[0 .. (rand @_)] }
sub random_subset(@) { randomize (random_prefix @_) }

for (;;) {
    my @avail = random_subset @l;
    my @want = random_subset (@l, @l2);
    my $which = which_lang(\@want, \@avail);
    print "which_lang([ qw(@want) ], [ qw(@avail) ]) is $which\n\n";
}

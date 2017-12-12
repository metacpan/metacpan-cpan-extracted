#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;

use Doit;

return 1 if caller();

plan 'no_plan';

require FindBin;
unshift @INC, $FindBin::RealBin;
require TestUtil;

my $doit = Doit->init;
$doit->add_component('locale');
ok $doit->can('locale_enable_locale'), "found method from component 'locale'";

SKIP: {
    my $test_count = 2;

    skip "Locale-adding code only active on travis", $test_count if !$ENV{TRAVIS};

    my $sudo = TestUtil::get_sudo($doit, info => \my %info);
    skip $info{error}, $test_count if !$sudo;

    my @try_locales = qw(de_DE.utf8 de_DE.UTF-8);
    my $res = $sudo->locale_enable_locale([@try_locales]);
    if ($res) {
	pass "de locale was added";
    } else {
	pass "de locale was already present";
    }

    {
	my $all_locales = $doit->qx({quiet=>1}, qw(locale -a));
	my $try_locales_rx = '(' . join('|', map { quotemeta $_ } @try_locales) . ')';
	ok grep { /$try_locales_rx/ } split /\n/, $all_locales;
    }
}

__END__

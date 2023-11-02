#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;

use Doit;
use Doit::Util qw(get_os_release);

return 1 if caller();

plan 'no_plan';

require FindBin;
unshift @INC, $FindBin::RealBin;
require TestUtil;

my $os_id = do {
    my $os_release = get_os_release();
    if ($os_release) {
	$os_release->{ID};
    } else {
	'';
    }
};

my $doit = Doit->init;
$doit->add_component('locale');
ok $doit->can('locale_enable_locale'), "found method from component 'locale'";
if ($os_id =~ m{^(fedora|rocky|centos)$}) {
    $doit->add_component('rpm'); # see also XXX comment in Doit::Locale
}
SKIP: {
    my $test_count = 2;

    skip "Locale-adding code only active on CI systems", $test_count if !$ENV{GITHUB_ACTIONS};

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

    ok !$sudo->locale_enable_locale([@try_locales]), '2nd install does nothing';
}

__END__

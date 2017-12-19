#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;

use Doit;

sub check_deb_component {
    my $d = shift;
    !!$d->can('deb_missing_packages');
}

sub check_git_component {
    my $d = shift;
    !!$d->can('git_repo_update');
}

return 1 if caller;

require FindBin;
{ no warnings 'once'; push @INC, $FindBin::RealBin; }
require TestUtil;

plan 'no_plan';

my $doit = Doit->init;
$doit->add_component('git');
pass 'add_component called with short component name';
$doit->add_component('Doit::Deb');
pass 'add_component called with module name';
eval { $doit->add_component('Doit::ThisComponentDoesNotExist') };
like $@, qr{ERROR:.* Cannot load Doit::ThisComponentDoesNotExist}, 'non-existing component';

ok $doit->call_with_runner('check_deb_component'), 'available deb component locally';
ok $doit->call_with_runner('check_git_component'), 'available git component locally';

# XXX $doit->{components} is an internal member!
is_deeply [map { $_->{module} } @{ $doit->{components} }], ['Doit::Git', 'Doit::Deb'], 'two components loaded';
$doit->add_component('git');
$doit->add_component('deb');
is_deeply [map { $_->{module} } @{ $doit->{components} }], ['Doit::Git', 'Doit::Deb'], 'still two components loaded';

SKIP: {
    my $number_of_tests = 2;

    my %info;
    my $sudo = TestUtil::get_sudo($doit, info => \%info);
    if (!$sudo) {
	skip $info{error}, $number_of_tests;
    }

    ok $sudo->call_with_runner('check_deb_component'), 'available deb component through sudo';
    ok $sudo->call_with_runner('check_git_component'), 'available git component through sudo';
}

__END__

#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use FindBin;

if (!eval { require Devel::Hide; 1 }) {
    require Test::More;
    Test::More::plan(skip_all => "No Devel::Hide available");
}

if ($] < 5.010) {
    require Test::More;
    Test::More::plan(skip_all => "Devel::Hide does no seem to work with perl 5.8.x");
    # At least an "eval { require IPC::Run; 1 }" does not fail with perl 5.8.9
}
    

$ENV{DEVEL_HIDE_PM} = 'IPC::Run';
system $^X, "-MDevel::Hide", "$FindBin::RealBin/write_binary.t";

__END__

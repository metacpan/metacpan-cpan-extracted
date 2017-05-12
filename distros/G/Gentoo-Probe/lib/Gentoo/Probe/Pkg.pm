package Gentoo::Probe::Pkg;
our($VERSION)=__VERSION__;
our(@ISA)=qw(Gentoo::Probe::Cmd);
use strict;$|=1;

use Gentoo::Probe::Cmd;
use Carp;

sub veto_args(%) {
	1;
}
1;

#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;

use Doit;
use Doit::User 'as_user';

######################################################################
# Functions run as sudo
sub can_run_test {
    defined $ENV{SUDO_USER};
}

sub run {
    my %res = (
	SUDO_USER => $ENV{SUDO_USER}
    );

    as_user {
	chomp(my $uname = `id -nu`);
	chomp(my $homedir = `sh -c 'echo ~'`);
	my($perlhomedir) = <~>;

	$res{uname}       = $uname;
	$res{homedir}     = $homedir;
	$res{perlhomedir} = $perlhomedir;
	$res{homeenv}     = $ENV{HOME};
	$res{userenv}     = $ENV{USER};
	$res{lognameenv}  = $ENV{LOGNAME};
    } $ENV{SUDO_USER};

    \%res;
}

return 1 if caller;

######################################################################
# MAIN

# Check if password-less sudo is available
require FindBin;
unshift @INC, $FindBin::RealBin;
require TestUtil;

my $sudo;
{
    my $doit = Doit->init;
    $sudo = TestUtil::get_sudo($doit, info => \my %info);
    if (!$sudo) {
	plan skip_all => $info{error};
    }
}

plan 'no_plan';

my $res = $sudo->call('run');

is $res->{uname},       $res->{SUDO_USER}, q{expected numeric user id (through id command)};
is $res->{homedir},     $ENV{HOME},        q{expected home directory (through tilde expansion with shell's glob)};
is $res->{perlhomedir}, $ENV{HOME},        q{expected home directory (through tilde expansion with perl's glob)};
is $res->{homeenv},     $ENV{HOME},        q{expected home directory (through environment)};
SKIP: {
    skip "USER environment variable not set", 1
	if !$ENV{USER}; # e.g. in docker
    is $res->{userenv}, $ENV{USER}, q{expected user (through environment)};
}
SKIP: {
    skip "LOGNAME environment variable not set", 1
	if !$ENV{LOGNAME}; # e.g. in docker
    is $res->{lognameenv}, $ENV{LOGNAME}, q{expected logname (through environment)};
}

__END__

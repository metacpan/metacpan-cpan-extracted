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
	$res{realuid}     = $<;
	$res{effuid}      = $>;
	$res{realgid}     = $(;
	$res{effgid}      = $);
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

plan skip_all => 'Does not work on Windows' if $^O eq 'MSWin32'; # too many unix-isms used
plan skip_all => 'cygwin does not have a root user' if $^O eq 'cygwin';
plan 'no_plan';

my $doit = Doit->init;

my($me) = getpwuid($<);

######################################################################
# error cases
{
    my $as_user_body_called;
    eval {
	as_user {
	    $as_user_body_called++;
	} 'this-user-does-not-exist-' . time;
    };
    like $@, qr{ERROR:.*Cannot get uid of user 'this-user-does-not-exist-\d+'}, 'as_user on non-existing user';
    is $as_user_body_called, undef;
}

{
    my $as_user_body_called;
    eval {
	as_user {
	    $as_user_body_called++;
	} $me, unhandled_option => 1;
    };
    like $@, qr{ERROR:.*Unhandled options: unhandled_option}, 'as_user with wrong option';
    is $as_user_body_called, undef;
}

######################################################################
# as_user $me (actually a no-op), with different cache settings
for my $cache (undef, 1, 1, 0) {
    my $uid_in_body = -1;
    as_user {
	$uid_in_body = $<;
    } $me, (defined $cache ? (cache => $cache) : ());
    is $uid_in_body, $<, "as_user set to $me (cache=" . (defined $cache ? $cache : '<undef>') . ")";
}

######################################################################
# as_user root
SKIP: {
    skip "haiku does not have a root user", 2 if $^O eq 'haiku';

    my $as_user_body_called;
    eval {
	as_user {
	    $as_user_body_called++;
	} 'root';
    };
    if ($< == 0) {
	is $@, '', 'as_user set to root';
	is $as_user_body_called, 1;
    } else {
	like $@, qr{ERROR:.*Can't set (real|effective) (group|user) id \(wanted: \d, is: \d+}, 'as_user set to root does not work';
	is $as_user_body_called, undef;
    }
}

######################################################################
# sudo-using tests
SKIP: {
    my $sudo = TestUtil::get_sudo($doit, info => \my %info);
    skip $info{error} if !$sudo;

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
    is $res->{realuid}, $<, 'expected user id';
    is((split / /, $res->{realgid})[0], (split / /, $()[0], 'expected first group id');
}

__END__

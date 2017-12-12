#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use Doit;
use Doit::User 'as_user';
use Doit::Util 'new_scope_cleanup';
use Test::More;

return 1 if caller;

plan skip_all => "Must run as root" if $< != 0;

require FindBin;
{ no warnings 'once'; push @INC, "$FindBin::RealBin/../t"; }
require TestUtil;

my $doit = Doit->init;

plan skip_all => "Creates user, should only run in test containers"
    if !TestUtil::in_linux_container($doit) && !$ENV{TRAVIS} && !$ENV{DOIT_TEST_XT_USER};

plan 'no_plan';

$doit->add_component('user');

$doit->user_account(
		    username => 'testdoit',
		    ssh_keys => ['dummy ssh key'],
		   );
{
    my(@pw) = getpwnam('testdoit');
    is $pw[0], 'testdoit', 'test user was created';
    is $pw[2], $pw[3], 'uid matches gid';
    ok -d $pw[7], 'home directory exists';
    if ($pw[8] ne '') { # empty string probably means: /bin/sh
	ok -x $pw[8], 'shell exists'
	    or diag "shell: $pw[8]";
    }
}

as_user {
    is $ENV{USER}, 'testdoit';
} 'testdoit';

$doit->user_account(
		    username => 'testdoit',
		    ensure   => 'absent',
		   );

{
    my(@pw) = getpwnam('testdoit');
    ok !defined $pw[0], 'test user was removed';
}

my $another_shell = sub {
    if (open my $fh, '/etc/shells') {
	while(<$fh>) {
	    chomp;
	    if (/^(.*bash.*)$/) {
		return $1;
	    }
	}
    }
    undef;
}->();
if ($another_shell) {
    Doit::Log::info("Found another shell: $another_shell");
}

$doit->user_account(
		    username => 'testdoit2',
		    ensure   => 'present',
		    uid      => 12345,
		    home     => '/home/testdoit2-xxx',
		    ($another_shell ? (shell => $another_shell) : ()),
		   );

{
    my(@pw) = getpwnam('testdoit2');
    is $pw[2], 12345;
    is $pw[3], 12345;
    ok -d $pw[7], 'home directory exists';
    is $pw[7], '/home/testdoit2-xxx', 'home directory as expected';
    if ($another_shell) {
	is $pw[8], $another_shell;
    }
}

as_user {
    is $ENV{USER}, 'testdoit2';
    is $ENV{HOME}, '/home/testdoit2-xxx';
    ok -d $ENV{HOME};
} 'testdoit2';

$doit->user_account(
		    username => 'testdoit2',
		    uid      => 12346,
		    home     => '/home/testdoit2-yyy',
		    shell    => '/bin/sh',
		   );

{
    my(@pw) = getpwnam('testdoit2');
    is $pw[2], 12346, 'uid after usermod';
    is $pw[3], 12345, 'gid after usermod still unchanged';
    ok -d $pw[7], 'home directory exists';
    is $pw[7], '/home/testdoit2-yyy', 'home directory as expected';
    is $pw[8], '/bin/sh';
}

as_user {
    is $ENV{USER}, 'testdoit2', 'USER env variable';
    is $ENV{HOME}, '/home/testdoit2-yyy', 'HOME env variable';
    ok -d $ENV{HOME};
} 'testdoit2', cache => 0; # XXX could the cache be invalidated automatically? should caching be off by default to avoid surprises?


SKIP: {
    skip "Only implemented for linux", 4 if $^O ne 'linux';

    # groupadd exists on Debian+RedHat, addgroup only on Debian
    my $scope_cleanup = new_scope_cleanup {
	eval { $doit->system('groupdel', 'testdoitgroup1') }; warning $@ if $@;
	eval { $doit->system('groupdel', 'testdoitgroup2') }; warning $@ if $@;
    };
    $doit->system('groupadd', 'testdoitgroup1');
    $doit->system('groupadd', 'testdoitgroup2');

    is $doit->user_add_user_to_group(username => 'testdoit2', group => 'testdoitgroup1'), 1, 'user was added to group';
    is $doit->user_add_user_to_group(username => 'testdoit2', group => 'testdoitgroup1'), 0, 'user is already in group';
    is $doit->user_add_user_to_group(username => 'testdoit2', group => 'testdoitgroup2'), 1, 'user was added to another group';
    is $doit->user_add_user_to_group(username => 'testdoit2', group => 'testdoitgroup2'), 0, 'user is already in group';
}

$doit->user_account(
		    username => 'testdoit2',
		    ensure   => 'absent',
		   );

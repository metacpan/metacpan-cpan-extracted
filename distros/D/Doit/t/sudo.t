#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Getopt::Long;
use Test::More;

use Doit;

sub get_id {
    my $d = shift;
    chomp(my $res = `id -u`);
    $res;
}

sub pwinfo {
    getpwuid($<);
}

sub envinfo { \%ENV }

sub stdout_test {
    print "This goes to STDOUT\n";
    4711;
}

sub stderr_test {
    print STDERR "This goes to STDERR\n";
    314;
}

return 1 if caller;

require FindBin;
{ no warnings 'once'; push @INC, $FindBin::RealBin; }
require TestUtil;

my $other_user;
my $debug;
GetOptions(
	   "other-user=s" => \$other_user,
	   "debug" => \$debug,
	  )
    or die "usage: $0 [--other-user username] [--debug]\n";

my $d = Doit->init;

if (!$d->which('sudo')) {
    plan skip_all => 'sudo not in PATH';
}

my %info;
my $sudo = TestUtil::get_sudo($d, info => \%info);
if (!$sudo) {
    plan skip_all => $info{error};
}

plan 'no_plan';

isa_ok $sudo, 'Doit::Sudo';

my $res = $sudo->call('get_id');
is $res, 0, 'switched to uid=0';

{
    my(@pwinfo) = $sudo->call('pwinfo');
    is $pwinfo[0], 'root';
    my $envinfo = $sudo->call('envinfo');
    is $envinfo->{DOIT_IN_REMOTE}, 1, 'DOIT_IN_REMOTE env var set';
}

is $sudo->call('stdout_test'), 4711;
is $sudo->call('stderr_test'), 314;

{
    my $res = $sudo->qx({quiet=>1}, 'perl', '-e', 'print "STDOUT without newline"');
    is $res, 'STDOUT without newline';
}

# not needed anymore, but try it anyway
$sudo->exit;

{
    my $sudo2 = $d->do_sudo(sudo_opts => ['-n'], debug => $debug);
    isa_ok $sudo2, 'Doit::Sudo';
    # hopefully no warnings on destroy
}

SKIP: {
    skip "--other-user option not set", 1
	if !defined $other_user;
    # -H (--set-home) may or may not be necessary
    my $sudo = $d->do_sudo(sudo_opts => ['-n', '-u', $other_user, '-H'], debug => $debug);
    my $res = eval { $sudo->call('get_id') };
    skip "Cannot run sudo -u password-less",1
	if $@;

    my(@pwinfo) = $sudo->call('pwinfo');
    is $pwinfo[0], $other_user;
    my $envinfo = $sudo->call('envinfo');
    is $envinfo->{HOME}, (getpwnam($other_user))[7], 'home directory of other user set to HOME env var';
    is $envinfo->{DOIT_IN_REMOTE}, 1, 'DOIT_IN_REMOTE env var set';
}

__END__

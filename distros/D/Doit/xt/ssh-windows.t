#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Getopt::Long;
use Test::More;
use Sys::Hostname 'hostname';

use Doit;
use Doit::Log;
use Doit::Util qw(in_directory);

sub test_doit {
    my $doit = shift;
    in_directory {
	eval { $doit->system(qw(git pull)) }; # XXX fails because forward_agent does not work (?) and tty is not enabled (and also does not work)
	warning "git pull failed: $@" if $@;
	$doit->system($^X, 'Build.PL');
	$doit->system($^X, 'Build');
	$doit->system($^X, 'Build', 'test');
    } 'Doit';
}

return 1 if caller;

plan skip_all => 'Only activated on specific systems'
    unless hostname eq 'cabulja';
plan 'no_plan';

my $user_host = 'IEUser@cabulja-win7';

my $doit = Doit->init;
GetOptions(
	   "test-doit" => \my $test_doit,
	   "debug"     => \my $debug,
	  )
    or die "usage?";

my $ssh = $doit->do_ssh_connect($user_host, dest_os => 'MSWin32', put_to_remote => 'scp_put', debug => $debug, forward_agent => 1);
ok $ssh, 'ssh object created';

{
    my $res = $ssh->info_qx('perl', '-e', 'print "It worked!"');
    is $res, 'It worked!', 'running command on remote worked';
}

if ($test_doit) {
    $ssh->call_with_runner('test_doit');
}

__END__

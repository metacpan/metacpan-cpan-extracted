#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#


use Test::More 'no_plan';

use Doit;
use File::Find qw(find);
use FindBin;
use Getopt::Long;

my $lib = "$FindBin::RealBin/../lib";

my @pms;
find sub { push @pms, $File::Find::name if /\.pm$/ }, $lib;

my $doit = Doit->init;

my $use_ipc_run;
GetOptions("use-ipc-run" => \$use_ipc_run)
    or die "usage?";

for my $pm (@pms) {
    my @cmd = ($^X, '-wc', '-Ilib='.$lib, ($pm !~ m{Doit\.pm$} ? ('-MDoit') : ()), $pm);
 SKIP: {
	my($stdout, $stderr);
	if ($^O eq 'MSWin32' || $use_ipc_run) {
	    skip "No IPC::Run available", 1
		if !$doit->can_ipc_run;
	    eval { $doit->run(\@cmd, '>', \$stdout, '2>', \$stderr) };
	    is "$@", '', "$pm compiles";
	} else {
	    $stdout = eval { $doit->open3({quiet=>1,instr=>'',errref=>\$stderr}, @cmd) };
	    is "$@", '', "$pm compiles";
	    $stdout = '' if !defined $stdout;
	    $stderr = '' if !defined $stderr;
	}
	is $stdout, '', 'Nothing on STDOUT';
	like $stderr, qr{\A.*\.pm syntax OK\n\z}, 'Nothing unexpected on STDERR';
    }
}

__END__

#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use Cwd 'getcwd';
use Doit;
use File::Temp qw(tempdir);
use Test::More;

sub environment {
    my($doit) = @_;
    require FindBin;
    my $original_realbin = $FindBin::RealBin;
    FindBin->again;
    my $refreshed_realbin = $FindBin::RealBin;
    return {
	cwd               => getcwd,
	original_realbin  => $original_realbin,
	refreshed_realbin => $refreshed_realbin,
	DOIT_IN_REMOTE    => $ENV{DOIT_IN_REMOTE},
    };
}

sub stdout_test {
    print "This goes to STDOUT\n";
}

sub remote_fail {
    Doit::Log::error("fail");
}

return 1 if caller;

plan skip_all => "Net::OpenSSH does not work on Windows" if $^O eq 'MSWin32'; # but it can still be installed
plan 'no_plan';

my $doit = Doit->init;

my @common_ssh_opts = ((defined $ENV{USER} ? $ENV{USER}.'@' : '') . 'localhost', master_opts => [qw(-oPasswordAuthentication=no -oBatchMode=yes -oConnectTimeout=3)]);

for my $test_type ('args', 'net-openssh-object') {
 SKIP: {
	my $ssh;
	if ($test_type eq 'args') {
	    $ssh = eval { $doit->do_ssh_connect(@common_ssh_opts, debug => 0) };
	} elsif ($test_type eq 'net-openssh-object') {
	    $ssh = eval {
		require Net::OpenSSH;
		my $net_openssh = Net::OpenSSH->new(@common_ssh_opts);
		$net_openssh->error and die $net_openssh->error;
		$ssh = $doit->do_ssh_connect($net_openssh, debug => 0);
	    };
	} else {
	    die "Unhandled test_type";
	}
	skip "Cannot do ssh localhost using test type '$test_type': $@", 1
	    if !$ssh;
	isa_ok $ssh, 'Doit::SSH';

	my $ret = $ssh->info_qx('perl', '-e', 'print "yes\n"');
	is $ret, "yes\n", 'run command via local ssh connection';

	my $env = $ssh->call_with_runner('environment');
	is $env->{cwd}, $ENV{HOME}, 'expected cwd is current home directory';

	## XXX Actually it's unclear what $FindBin::RealBin should return here
	#is($env->{original_realbin}, '???');
	#is($env->{refreshed_realbin}, '???');
	is $env->{DOIT_IN_REMOTE}, 1, 'DOIT_IN_REMOTE env set';

	# XXX currently the output is not visible ---
	# to work around this problem $|=1 has to be set in the function
	# This should be done automatically.
	# Another possibility: call $ssh->exit. But this would mean that
	# the output only appears at the exit() call, not before.
	# Also, this should be a proper test, e.g. using Capture::Tiny
	$ssh->call_with_runner('stdout_test');

	is $ssh->exit, 'bye-bye', 'exit called'; # XXX hmmm, should this really return "bye-bye"?

	eval { $ssh->system($^X, '-e', 'exit 0') };
	isnt $@, '', 'calling on ssh after exit';

    SKIP: {
	    skip "Symlinks on Windows?", 1 if $^O eq 'MSWin32';

	    # Do a symlink test
	    my $dir = tempdir("doit_XXXXXXXX", TMPDIR => 1, CLEANUP => 1);
	    $doit->write_binary({quiet=>1}, "$dir/test-doit.pl", <<'EOF');
use Doit;
return 1 if caller;
my $doit = Doit->init;
my $ssh = $doit->do_ssh_connect((defined $ENV{USER} ? $ENV{USER}.'@' : '') . 'localhost', debug => 0, master_opts => [qw(-oPasswordAuthentication=no -oBatchMode=yes -oConnectTimeout=3)]);
my $ret = $ssh->info_qx('perl', '-e', 'print "yes\n"');
print $ret;
EOF
	    $doit->chmod(0755, "$dir/test-doit.pl");
	    $doit->symlink("$dir/test-doit.pl", "$dir/test-symlink.pl");
	    my $ret = $doit->info_qx($^X, "$dir/test-symlink.pl");
	    is $ret, "yes\n";
	}
    }
}

{
    my $dir = tempdir("doit_XXXXXXXX", TMPDIR => 1, CLEANUP => 1);
    $doit->write_binary({quiet=>1}, "$dir/test-doit.pl", <<'EOF');
use Doit;
sub fail_on_remote {
    Doit::Log::error("fail on remote");
}
return 1 if caller;
my $doit = Doit->init;
my $ssh = $doit->do_ssh_connect((defined $ENV{USER} ? $ENV{USER}.'@' : '') . 'localhost', debug => 0, master_opts => [qw(-oPasswordAuthentication=no -oBatchMode=yes -oConnectTimeout=3)]);
$ssh->call_with_runner("fail_on_remote");
Doit::Log::warning("This should never be reached!");
EOF
    $doit->chmod(0755, "$dir/test-doit.pl");
    my $ret = eval { $doit->system($^X, "$dir/test-doit.pl"); 1 };
    ok !$ret, 'system command failed';
    like $@, qr{^Command exited with exit code (\d+) at}, 'expected error message';
    isnt $1, 0, 'exit code is not zero';
}

__END__

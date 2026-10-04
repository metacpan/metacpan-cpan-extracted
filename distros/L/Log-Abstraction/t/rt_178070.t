#!/usr/bin/env perl
# t/rt_178070.t -- RT#178070: tests failed with Readonly::Values::Syslog 0.03
#
# Readonly::Values::Syslog 0.03 set trace to 6 (debug is 7), so is_debug()
# was false at trace level, and it has no 'critical', 'crit', 'fatal',
# 'emerg' or 'panic' keys (it spells one 'criticial').  0.04 fixed both,
# and Log::Abstraction has required it since 0.30.

use strict;
use warnings;

use Config;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use Test::Most;

use Log::Abstraction;
use Readonly::Values::Syslog;

# Run the perl script $script in a child, with $dir searched before the
# current @INC.  Returns the exit status and the combined output.
#
# On Windows, IPC::Open3 joins the command into one line without quoting it,
# so an argument containing spaces is split (a "-e" script then reaches perl
# as just "require").  Hence code goes in a script file, the library path
# goes in PERL5LIB rather than -I options, and what's left (perl and the
# script, whose paths may contain spaces) is quoted on Windows
sub run_script {
	my ($dir, $script) = @_;

	local $ENV{PERL5LIB} = join($Config{path_sep}, $dir, grep { !ref } @INC);
	my @cmd = map { (($^O eq 'MSWin32') && /\s/) ? qq{"$_"} : $_ } ($^X, $script);
	my $pid = open3(my $in, my $out, undef, @cmd);
	close $in;
	my $output = do { local $/; <$out> } // '';
	# A Windows child writes CRLF line endings, which would stop /^...$/m matching
	$output =~ s/\r\n/\n/g;
	waitpid($pid, 0);
	return ($? >> 8, $output);
}

# Run perl code in a child, as run_script does
my $scripts = 0;
sub run_perl {
	my ($dir, $code) = @_;

	my $script = File::Spec->catfile($dir, 'child' . ++$scripts . '.pl');
	open(my $fout, '>', $script) or die "$script: $!";
	print $fout $code, "\n";
	close $fout;
	return run_script($dir, $script);
}

subtest 'the loaded Readonly::Values::Syslog is new enough' => sub {
	cmp_ok(Readonly::Values::Syslog->VERSION, '>=', 0.04, 'version is at least 0.04');
	is($syslog_values{trace}, $syslog_values{debug}, 'trace has the same value as debug');
	is($syslog_values{trace}, 7, 'trace is 7');
	for my $name (qw(critical crit fatal emergency emerg panic alert)) {
		ok(defined($syslog_values{$name}), "'$name' is a known level");
	}
};

subtest 'is_debug() is true at trace level (the reported failure)' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'trace', logger => \@array);

	is($log->is_debug(), 1, 'is_debug at trace');
	is($log->is_trace(), 1, 'is_trace at trace');
	$log->debug('d')->trace('t');
	is_deeply([ map { $_->{level} } @array ], ['debug', 'trace'], 'debug and trace both logged');

	$log = Log::Abstraction->new(level => 'debug', logger => \@array);
	is($log->is_trace(), 1, 'is_trace at debug: trace shares the threshold');
};

subtest 'levels missing from 0.03 work' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'crit', logger => \@array);

	$log->error('dropped')->critical('kept');
	is_deeply([ map { $_->{message} } @array ], ['kept'], "level 'crit' is the critical threshold");
	lives_ok(sub { Log::Abstraction->new(level => $_, logger => []) }, "level '$_' accepted")
		for(qw(critical fatal emerg panic));
};

subtest 'Log::Abstraction refuses to load with 0.03' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $path = File::Spec->catdir($dir, 'Readonly', 'Values');
	require File::Path;
	File::Path::make_path($path);
	open(my $fout, '>', File::Spec->catfile($path, 'Syslog.pm')) or die "$path: $!";
	print $fout "package Readonly::Values::Syslog;\nour \$VERSION = '0.03';\n1;\n";
	close $fout;

	my ($status, $output) = run_perl($dir, 'require Log::Abstraction; print "loaded\n"');
	isnt($status, 0, 'require fails');
	like($output, qr/Readonly::Values::Syslog version 0\.04 required--this is only version 0\.03/,
		'with a clear version message');
	unlike($output, qr/^loaded$/m, 'and does not load');
};

done_testing();

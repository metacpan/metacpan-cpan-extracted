#!/usr/bin/env perl
# t/rt_180018.t -- RT#180018: two failures on CPAN Testers
#
# 1. With Sub::Private 0.04 the subs marked :Private vanished, so every log
#    call died with 'Can't locate object method "_log"'.  Sub::Private 0.05
#    is required since Log::Abstraction 0.34.
# 2. Without Log::Any (only a recommended dependency), t/10-compile.t failed
#    with "Can't locate Log/Any/Adapter/Base.pm".  Since 0.35 it skips the
#    adapter instead.

use strict;
use warnings;

use Config;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use Test::Most;

use Log::Abstraction;

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

# Write a file below $dir, creating directories as needed
sub write_file {
	my ($dir, $relpath, $content) = @_;

	my $file = File::Spec->catfile($dir, split(m{/}, $relpath));
	my ($vol, $path) = File::Spec->splitpath($file);
	require File::Path;
	File::Path::make_path(File::Spec->catpath($vol, $path, ''));
	open(my $fout, '>', $file) or die "$file: $!";
	print $fout $content;
	close $fout;
	return $file;
}

subtest 'the private subs exist' => sub {
	cmp_ok(Sub::Private->VERSION, '>=', 0.05, 'Sub::Private is at least 0.05');
	for my $sub (qw(_log _high_priority _validate_file_path _format_message _write_line
			_journald_send _sanitize_email_header _level_number _to_json _field_string _fields_text)) {
		ok(defined(&{"Log::Abstraction::$sub"}), "$sub is defined");
	}
};

subtest 'every logging method reaches _log' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'trace', logger => \@array);

	my @methods = qw(trace debug info notice warn error fatal critical alert emergency);
	for my $method (@methods) {
		lives_ok(sub { $log->$method("$method message") }, "$method() does not die");
	}
	is(scalar(@array), scalar(@methods), 'every message logged');
	unlike(join('', map { $_->{message} } @array), qr/Can't locate object method/, 'no missing-method error');
};

subtest 'Log::Abstraction refuses to load with Sub::Private 0.04' => sub {
	my $dir = tempdir(CLEANUP => 1);
	write_file($dir, 'Sub/Private.pm', "package Sub::Private;\nour \$VERSION = '0.04';\n1;\n");

	my ($status, $output) = run_perl($dir, 'require Log::Abstraction; print "loaded\n"');
	isnt($status, 0, 'require fails');
	like($output, qr/Sub::Private version 0\.05 required--this is only version 0\.04/,
		'with a clear version message, not a missing _log at log time');
};

# A module that makes Log::Any look uninstalled, in this perl and any it
# starts (through PERL5OPT).  The adapter itself stays loadable, so that
# loading it fails on Log::Any::Adapter::Base, as in the report
my $HIDER = <<'EOF';
package HideLogAny;
unshift @INC, sub {
	die "Can't locate $_[1] in \@INC (hidden by HideLogAny)\n"
		if(($_[1] =~ m{^Log/Any(?:\.pm|/)}) && ($_[1] ne 'Log/Any/Adapter/Abstraction.pm'));
	return;
};
1;
EOF

subtest 'Log::Abstraction works without Log::Any' => sub {
	my $dir = tempdir(CLEANUP => 1);
	write_file($dir, 'HideLogAny.pm', $HIDER);

	my ($status, $output) = run_perl($dir,
		'use HideLogAny; require Log::Abstraction; my @a; Log::Abstraction->new(logger => \@a, level => "info")->info("ok"); print "logged $a[0]{message}\n"');
	is($status, 0, 'Log::Abstraction loads and logs');
	like($output, qr/^logged ok$/m, 'message logged');

	($status, $output) = run_perl($dir, 'use HideLogAny; require Log::Any::Adapter::Abstraction');
	isnt($status, 0, 'the adapter needs Log::Any');
	like($output, qr{Can't locate Log/Any/Adapter/Base\.pm}, 'and fails as in the report');
};

subtest 't/10-compile.t skips the adapter without Log::Any' => sub {
	plan skip_all => 'Test::Compile not installed' unless(eval { require Test::Compile; 1 });
	my $compile_test = File::Spec->catfile('t', '10-compile.t');
	plan skip_all => "$compile_test not found" unless(-r $compile_test);

	my $dir = tempdir(CLEANUP => 1);
	write_file($dir, 'HideLogAny.pm', $HIDER);

	# Test::Compile checks each file in a new perl, so hide Log::Any in
	# those too (run_script puts $dir in PERL5LIB)
	local $ENV{PERL5OPT} = '-MHideLogAny';

	my ($status, $output) = run_script($dir, $compile_test);
	is($status, 0, "$compile_test passes") or diag($output);
	like($output, qr{^ok \d+ # skip \S*Log/Any/Adapter/Abstraction\.pm: Log::Any not installed}m,
		'the adapter is skipped');
	unlike($output, qr{Can't locate Log/Any/Adapter/Base\.pm}, 'no missing Log::Any error');
};

done_testing();

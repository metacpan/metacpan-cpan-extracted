#!/usr/bin/env perl
# t/private_runtime.t -- the :Private subs are enforced when Log::Abstraction
# is loaded at run time (require, string eval, Log::Any::Adapter->set).
#
# Before Sub::Private 0.06 that was too late for its CHECK block: enforcement
# was silently off and "Too late to run CHECK block" was printed.
#
# The harness sets HARNESS_ACTIVE, which turns enforcement off, so each check
# runs in a child perl with it removed.

use strict;
use warnings;

use Config;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use Test::Most;

# Run the perl code $code in a child without HARNESS_ACTIVE.  Returns the
# exit status and the combined output.
#
# On Windows, IPC::Open3 joins the command into one line without quoting it,
# so the code goes in a script file, the library path in PERL5LIB, and perl
# and the script are quoted when their paths contain spaces (see
# t/rt_180018.t)
my $dir = tempdir(CLEANUP => 1);
my $scripts = 0;
sub run_perl {
	my $code = $_[0];

	my $script = File::Spec->catfile($dir, 'child' . ++$scripts . '.pl');
	open(my $fout, '>', $script) or die "$script: $!";
	print $fout $code, "\n";
	close $fout;

	local $ENV{PERL5LIB} = join($Config{path_sep}, grep { !ref } @INC);
	delete local $ENV{HARNESS_ACTIVE};
	my @cmd = map { (($^O eq 'MSWin32') && /\s/) ? qq{"$_"} : $_ } ($^X, $script);
	my $pid = open3(my $in, my $out, undef, @cmd);
	close $in;
	my $output = do { local $/; <$out> } // '';
	$output =~ s/\r\n/\n/g;
	waitpid($pid, 0);
	return ($? >> 8, $output);
}

# Code that reports, one line each, whether a function and a method call
# to a private sub from main are blocked, then logs through the public API
my $probe = <<'EOF';
my $f = eval { Log::Abstraction::_level_number('debug'); 1 } ? 'allowed' : $@;
print 'function: ', ($f =~ /is a private subroutine of Log::Abstraction/ ? 'blocked' : $f), "\n";
my $log = Log::Abstraction->new(level => 'debug', logger => \my @msgs);
my $m = eval { $log->_timestamp(time); 1 } ? 'allowed' : $@;
print 'method: ', ($m =~ /is a private subroutine of Log::Abstraction/ ? 'blocked' : $m), "\n";
$log->debug('d');
$log->warn('w', { k => 1 });
$log->{format} = 'json';
$log->info('i');
print 'logged: ', scalar(@msgs), "\n";
EOF

for my $load ('require Log::Abstraction;', q{eval 'use Log::Abstraction; 1' or die $@;}) {
	subtest "loaded with $load" => sub {
		my ($status, $output) = run_perl(
			'use strict; use warnings; my @w; $SIG{__WARN__} = sub { push @w, @_ };' .
			"$load\n$probe" . 'print "warning: $_" for @w;'
		);
		is($status, 0, 'child exits cleanly') or diag($output);
		like($output, qr/^function: blocked$/m, 'private function call is blocked');
		like($output, qr/^method: blocked$/m, 'private method call is blocked');
		like($output, qr/^logged: 3$/m, 'the public methods still work');
		unlike($output, qr/^warning:/m, 'no warnings (e.g. "Too late to run CHECK block")');
	};
}

subtest 'loaded at compile time' => sub {
	my ($status, $output) = run_perl("use strict; use warnings; use Log::Abstraction;\n$probe");
	is($status, 0, 'child exits cleanly') or diag($output);
	like($output, qr/^function: blocked$/m, 'private function call is blocked');
	like($output, qr/^method: blocked$/m, 'private method call is blocked');
	like($output, qr/^logged: 3$/m, 'the public methods still work');
};

subtest 'loaded through Log::Any::Adapter->set' => sub {
	eval { require Log::Any; require Log::Any::Adapter; 1 } or plan(skip_all => "Log::Any is not installed\n");

	my ($status, $output) = run_perl(<<'EOF');
use strict; use warnings;
my @w; $SIG{__WARN__} = sub { push @w, @_ };
require Log::Any; require Log::Any::Adapter;
my @msgs;
Log::Any::Adapter->set('Abstraction', level => 'debug', logger => \@msgs);
Log::Any->get_logger->debug('d');
my $f = eval { Log::Abstraction::_level_number('debug'); 1 } ? 'allowed' : $@;
print 'function: ', ($f =~ /is a private subroutine of Log::Abstraction/ ? 'blocked' : $f), "\n";
print 'logged: ', scalar(@msgs), "\n";
print "warning: $_" for @w;
EOF
	is($status, 0, 'child exits cleanly') or diag($output);
	like($output, qr/^function: blocked$/m, 'private function call is blocked');
	like($output, qr/^logged: 1$/m, 'logging through Log::Any works');
	unlike($output, qr/^warning:/m, 'no warnings');
};

done_testing();

package TestLogging;
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Exporter 'import';
our @EXPORT= qw( capture_output test_log_method );

# my ($stdout, $stderr)= capture_output( \&coderef )
sub capture_output(&) {
	my $code= shift;
	my ($stdout, $stderr)= ('', '');
	my $tb= Test::Builder->new if Test::Builder->can('new');
	my ($out, $fout);
	try {
		# Set up capture for stdout/stderr
		local *STDOUT;
		local *STDERR;
		open STDOUT, '>', \$stdout or die "Can't redirect stdout to a memory buffer: $!";
		open STDERR, '>', \$stderr or die "Can't redirect stderr to a memory buffer: $!";
		
		# Also capture Test::Builder output
		my $out= $tb->output if $tb;
		my $fout= $tb->failure_output if $tb;
		$tb->output(\*STDOUT) if $tb;
		$tb->failure_output(\*STDERR) if $tb;
		
		# Now run the code
		$code->();
	} finally {
		# restore handles
		$tb->output($out) if $tb;
		$tb->failure_output($fout) if $tb;
	};
	return ($stdout, $stderr);
}

sub test_log_method {
	my ($log, $method, $message, $stdout_pattern, $stderr_pattern)= @_;
	my ($stdout, $stderr)= capture_output { $log->$method($message) };
	if (ref $stdout_pattern) {
		like( $stdout, $stdout_pattern, "result of $method($message) stdout" );
	} else {
		is( $stdout, $stdout_pattern, "result of $method($message) stdout" );
	}
	if (ref $stderr_pattern) {
		like( $stderr, $stderr_pattern, "result of $method($message) stderr" );
	} else {
		is( $stderr, $stderr_pattern, "result of $method($message) stderr" );
	}
}

1;
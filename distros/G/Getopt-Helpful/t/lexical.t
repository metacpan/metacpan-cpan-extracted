#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IPC::Run qw(run);

my $dump;
$ARGV[0] and ($dump = 1);

use Getopt::Helpful;

my $perl = $^X;

my $test_code = <<'TEST_CODE';
use warnings;
use strict;
use Data::Dumper;
my $option = "no";
my $var = "default";
our $debug = 0;
our $verbose = 0;
use Getopt::Helpful;
my $hopt = Getopt::Helpful->new(
	usage => 'perl CALLER',
	[
		'o|option=s', \$option,
		'<option>',
		"setting for \$option (default: '$option')",
	],
	[
		'var=s', \$var,
		'<setting>',
		"setting for \$var (default: '$var')"
	],
	'+verbose',
	'+debug',
	'+help'
	);
main(@ARGV);
sub main {
	my (@args) = @_;
	$hopt->Get_from(\@args);
	print Dumper({v => $verbose, d => $debug, o => $option, x => $var,
		a => join(" ", @args), A => join(" ", @ARGV)});
}
TEST_CODE

my @args = (
	[
		[],
		{v => 0, d => 0, o => 'no', x => 'default', a => '', A => ''},
	],
	[
		[qw(--verbose --option no --var default)],
		{v => 1, d => 0, o => 'no', x => 'default', a => ''},
	],
	[
		[qw(-v foo --var whee bar --option no baz)],
		{v => 1, d => 0, o => 'no', x => 'whee', a => 'foo bar baz'},
	],
	);

plan(tests =>
	1 +
	scalar(@args) * 4 +
	0);

{
	my ($in, $out, $err);
	ok(run([$perl, qw(-e), $test_code], \$in, \$out, \$err), 'compile') or
		die "test_code does not compile: $err";
}

foreach my $arg (@args) {
	my %exp = %{$arg->[1]};
	my @argv = @{$arg->[0]};
	$exp{A} ||= join(" ", @argv);
	res_check(\%exp, $perl, '-e', $test_code, '--', @argv);
}

exit;
########################################################################

use Data::Dumper;
=head1 Functions

=head2 res_check

Compares Dumper output to %expect.

  res_check(\%expect, @run);

=cut
sub res_check {
	my ($expect, @run) = @_;
	my $string = Dumper($expect);
	my $out = catch(@run);
	SKIP: {
		length($out) or skip("nothing to compare", 1);
		my $var = eval("no strict;no warnings;$out");
		$@ and die "$@";
		# warn "$var->{d}, $expect->{d}\n";
		is_deeply($expect, $var, 'matchy-matchy') or 
			warn "$out ($expect) should have been\n$string ($var)\n";
		$dump and warn "$out";
	}
} # end subroutine res_check definition
########################################################################

=head2 catch

Catches STDOUT from running @command, and issues ok() for no-stderr and
exit-code tests.

  my $stdout = catch(@command);

=cut
sub catch {
	my ($in, $out, $err);
	ok(run([@_], \$in, \$out, \$err), 'exit-code') or warn "RUN ERROR: $err";
	ok($err eq '', "clean-stderr");
	if(length($err)) {
		$err =~ s/\n/\n     /g;
		$err =~ s/\s*$//;
		$err = '   ' . $err;
		warn "WARNING: $err\n";
	}
	ok(length($out), 'some output');
	return($out);
} # end subroutine catch definition
########################################################################


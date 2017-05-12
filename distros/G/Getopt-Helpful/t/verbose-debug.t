#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IPC::Run qw(run);

my $perl = $^X;

my $dump;
$ARGV[0] and ($dump = 1);

my @args = (
	[
		[qw(--verbose)],
		{v => 1, d => 0},
	],
	[
		[qw(--verbose --debug)],
		{v => 1, d => 1},
	],
	[
		[qw(--debug)],
		{v => 0, d => 1},
	],
	[
		['-v', '-d'],
		{v => 1, d => 1},
	],
	[
		['-v'],
		{v => 1, d => 0},
	],
#	[
#		['-dv'],
#		{v => 1, d => 1},
#	],
	);

plan(tests =>
	0 +
	scalar(@args) * 4 +
	0);

use Getopt::Helpful;

my $test_code = <<'TEST_CODE';
use Data::Dumper;
our $debug = 0;
our $verbose = 0;
use Getopt::Helpful;
my $hopt = Getopt::Helpful->new(
	usage => 'perl CALLER',
	'+verbose',
	'+debug',
	'+help'
	);
$hopt->Get();
print Dumper({v => $verbose, d => $debug});
TEST_CODE

foreach my $arg (@args) {
	res_check($arg->[1], $perl, '-e', $test_code, '--', @{$arg->[0]});
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
		ok($string eq $out, 'matchy-matchy') or 
			warn "$out should have been\n$string\n";
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
	ok(run([@_], \$in, \$out, \$err), 'exit-code') or warn "RUN ERR: $err";
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


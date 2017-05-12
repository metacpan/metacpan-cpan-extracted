
use strict;
use warnings;

use Test::More qw(
	no_plan
	);
use IPC::Run qw(run);
use YAML;
use Data::Dumper;

my $perl = $^X;

my @checks = (
	# hard-coded defaults check
	[
		[qw()],
		sub {
			res_check(
				{
					option => 'no',
					var => 'default',
				},
				@_);
		},
	],
	[
		[qw(-o foo -v lork)],
		sub {
			res_check(
				{
					option => 'foo',
					var => 'lork',
				},
				@_);
		},
	],
	[
		[qw(--option foo --var lork)],
		sub {
			res_check(
				{
					option => 'foo',
					var => 'lork',
				},
				@_);
		},
	],
	[
		[qw(--option foo)],
		sub {
			res_check(
				{
					option => 'foo',
					var => 'default',
				},
				@_);
		},
	],
	[
		[qw(--splork)],
		sub {
			err_check(@_);
		}
	],
	);

use File::Basename;
my $cmd = dirname($0);
length($cmd) and ($cmd =~ s#/*$#/#);
$cmd .= "./noconf_standard-run.pl";
ok((-e $cmd), "$cmd existence") or exit;

# XXX regenerate config files here...
my $num = 0;
foreach my $check (@checks) {
	#print "number: $num\n";
	$check->[1]->($perl, $cmd, @{$check->[0]});
	$num++;
}

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
	}
} # end subroutine res_check definition
########################################################################

=head2 err_check

Looks for a (-h for usage) error.

  err_check(@run);

=cut
sub err_check {
	my ($in, $out, $err);
	ok(run([@_], \$in, \$out, \$err) == 0, 'exit-code');
	ok(length($err), 'error present');
	ok($err =~ m/\(-h for help\)/, 'help pointer');
} # end subroutine err_check definition
########################################################################

=head2 catch

Catches STDOUT from running @command, and issues ok() for no-stderr and
exit-code tests.

  my $stdout = catch(@command);

=cut
sub catch {
	my ($in, $out, $err);
	ok(run([@_], \$in, \$out, \$err), 'exit-code');
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

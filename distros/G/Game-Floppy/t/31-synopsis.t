#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Floppy;

# THE SYNOPSIS IS RUN. It is cut out of the module that was loaded, so it is
# the text a reader sees, and it has to run, say nothing it did not mean to,
# and end with the one sentence a finished game prints.

my $file = $INC{'Game/Floppy.pm'};
open my $fh, '<', $file or die "$file: $!";
my $pod = do { local $/; <$fh> };
close $fh;

my ($synopsis) = $pod =~ /^=head1 SYNOPSIS\n(.*?)^Or, from a shell:/ms;
ok(defined $synopsis, 'the module has a SYNOPSIS with code before the shell lines') or BAIL_OUT('nothing to run');
my @lines = grep { /\S/ } split /\n/, $synopsis;
is(scalar(grep { !/\A {4}/ } @lines), 0, 'every line of it is code');
cmp_ok(scalar(@lines), '>=', 8, scalar(@lines) . ' lines');

my $printed = '';
open my $out, '>', \$printed or die $!;
my $previous = select $out;
my @warned;
my $ran = do {
	local $SIG{__WARN__} = sub { push @warned, @_ };
	eval "package SynopsisRun; use strict; use warnings;\n$synopsis\n1;";
};
my $died = $@;
select $previous;

ok($ran, 'it runs to the end') or diag($died);
is("@warned", '', 'with no warning');
like($printed, qr/\AGame over: (?:hit a tube|fell to the ground|flew off the top) at \d+ points after \d+ ticks\n\z/,
	'and prints the one sentence of a finished game');

done_testing();

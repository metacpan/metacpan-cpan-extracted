use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use FnCapture;

use Game::Fanorona;

# THE SYNOPSIS IS RUN. It is cut out of the module that was loaded, so it is
# the text a reader sees, and what it prints is compared with what its own
# comments say it prints.

my $file = $INC{'Game/Fanorona.pm'};
open my $fh, '<', $file or die "$file: $!";
my $pod = do { local $/; <$fh> };
close $fh;

my ($synopsis) = $pod =~ /^=head1 SYNOPSIS\n(.*?)^=head1 /ms;
ok(defined $synopsis, 'the module has a SYNOPSIS') or BAIL_OUT('nothing to run');
my @lines = grep { /\S/ } split /\n/, $synopsis;
is(scalar(grep { !/\A {4}/ } @lines), 0, 'every line of it is code');
cmp_ok(scalar(@lines), '>=', 10, scalar(@lines) . ' lines');

my $printed = '';
my $out = FnCapture->handle(\$printed);
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

my @said = split /\n/, $printed;
my @promised = map { /print .*#\s*(.+?)\s*\z/ ? $1 : () } @lines;
is(scalar(@promised), 2, 'two of its lines say in a comment what they print');
is($said[0], $promised[0], "the first prints what it says: $promised[0]");
is($said[1], $promised[1], "and the second: $promised[1]");
cmp_ok(scalar(grep { /\A[a-i][1-5]-[a-i][1-5][AW]? takes/ } @said), '>=', 1, 'the loop over the steps printed steps');

done_testing();

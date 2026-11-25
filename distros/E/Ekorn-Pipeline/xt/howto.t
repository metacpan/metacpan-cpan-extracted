use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use File::Spec qw();
use File::Temp qw(tempdir);

use lib 'xt/lib';
use Examples qw(md_examples expected matches);

# Run the examples in docs/HOWTO.md, the user guide, as one program, so
# they can't drift from the code, and check that each prints what its
# comments say. They share the examples' data, set up by the first,
# which makes its files in a temporary folder of its own, and follow on
# from each other: the first runs as it is, and each after it in a block
# of its own, so their names don't clash. An example marked
# <!-- not run --> is left out. What an example prints is in its
# comments, as xt/lib/Examples.pm says. It came from DBIx-Squirrel's
# xt/howto.t on 2026-11-13; its helpers moved to xt/lib/Examples.pm on
# 2026-11-25, for xt/examples.t too (roadmap 2026-0053).

my $HOWTO = 'docs/HOWTO.md';
skip_all "$HOWTO isn't here" unless -e $HOWTO;

my($first, @rest) = md_examples($HOWTO);
ok $first, 'the how-to has examples' or done_testing, exit;

# Each example's lines are numbered as they are in the how-to, so an
# error names the how-to's line. Before each, a line marks where its
# output starts.
my $MARK    = "\x{1E}";
my $program = join '',
    qq{print "$MARK$first->[0]\\n";\n#line $first->[0] "$HOWTO"\n$first->[1]},
    map { qq(print "$MARK$_->[0]\\n";\n{\n#line $_->[0] "$HOWTO"\n$_->[1]}\n) }
    @rest;

# Run it in a directory of its own, with what it writes to STDERR kept
# apart.
my $lib = File::Spec->rel2abs('lib');
my $dir = tempdir(CLEANUP => 1);
open my $out, '>', "$dir/howto.pl" or die "Can't write $dir/howto.pl: $!";
print { $out } $program;
close $out or die "Can't write $dir/howto.pl: $!";
my $printed = qx(cd "$dir" && "$^X" "-I$lib" howto.pl 2>stderr);

is $?, 0, sprintf 'the %d examples run', 1 + @rest;
open my $err, '<', "$dir/stderr" or die "Can't read $dir/stderr: $!";
is do { local $/; <$err> }, '', 'without warnings or errors';

my %printed;
for my $part (split m( $MARK )x, $printed) {
    my($line, @lines) = split m( \n )x, $part;
    $printed{$line} = [map { s( \s+ \z )()xr } @lines] if defined $line;
}
for my $example ($first, @rest) {
    my($line, $code) = @$example;
    my @said = expected($code);
    my @got  = @{ $printed{$line} // [] };
    my $ok   = @got == @said && !grep { !matches($got[$_], $said[$_]) } 0 .. $#said;
    ok $ok, "the example at line $line prints what its comments say"
        or diag "printed:\n", map({ "    $_\n" } @got), "its comments say:\n",
        map { "    $_\n" } @said;
}

done_testing;

use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use File::Spec qw();
use File::Temp qw(tempdir);

use lib 'xt/lib';
use Examples qw(md_examples pod_examples expected matches);

# The examples in docs/REFERENCE.md and README.pod, so they can't drift
# from the code, as xt/howto.t checks the how-to's (roadmap 2026-0053).
#
# Each of the reference's examples before its index, whose entries are
# synopses, runs in a program of its own, after the reference's
# catalogue of tracks, in a folder holding the files its examples read,
# and must run without warnings or errors, and print what its comments
# say, as xt/lib/Examples.pm reads them. Each runs alone, as many
# define the same names, such as lines_of. One that can't, such as one
# that croaks on purpose, or uses a stand-in such as a statement handle,
# is marked <!-- not run -->, and checked by hand.
#
# The README's examples use stand-ins, such as users() and fetch_page,
# so each is compiled, after the same catalogue, rather than run. One
# that isn't Perl is marked =for not-run.

my $REFERENCE = 'docs/REFERENCE.md';
my $README    = 'README.pod';
skip_all "$REFERENCE isn't here" unless -e $REFERENCE;

my $lib = File::Spec->rel2abs('lib');
my $dir = tempdir(CLEANUP => 1);

# The files the reference's examples read.
my %files = (
    'setlist.txt'  => "Intro\nParklife\nSong 2\nencore\nTender\n",
    'original.txt' => "Dancing Queen\nParklife\n",
);
for my $name (sort keys %files) {
    open my $out, '>', "$dir/$name" or die "Can't write $dir/$name: $!";
    print { $out } $files{$name};
    close $out or die "Can't write $dir/$name: $!";
}

# The reference's catalogue, the example that declares @tracks, after
# what every example assumes is loaded.
my @examples = md_examples($REFERENCE, '## Index');
my($catalogue) = grep { $_->[1] =~ m( \A my\ \@tracks\ =\  )x } @examples;
ok $catalogue, 'the reference has its catalogue' or done_testing, exit;
my $preamble = <<"END" . $catalogue->[1];
use v5.36;
use Ekorn::Pipeline;
use Ekorn::Pipeline::Tooling qw(:all);
#line $catalogue->[0] "$REFERENCE"
END

# Run a program in the folder, giving its exit status, what it printed,
# and what it wrote to STDERR. With -c, it's only compiled.
sub run ($program, @switches) {
    open my $out, '>', "$dir/example.pl" or die "Can't write $dir/example.pl: $!";
    print { $out } $program;
    close $out or die "Can't write $dir/example.pl: $!";
    my $printed = qx(cd "$dir" && "$^X" "-I$lib" @switches example.pl 2>stderr);
    my $status  = $?;
    open my $err, '<', "$dir/stderr" or die "Can't read $dir/stderr: $!";
    my $stderr = do { local $/ = undef; <$err> };
    close $err;
    return ($status, $printed, $stderr);
}

for my $example (grep { $_ != $catalogue } @examples) {
    my($line, $code) = @$example;
    my($status, $printed, $stderr)
        = run("$preamble\n{\n#line $line \"$REFERENCE\"\n$code}\n");
    my @said = expected($code);
    my @got  = map { s( \s+ \z )()xr } split m( \n )x, $printed;
    my $ok
        = $status == 0
        && $stderr eq ''
        && @got == @said
        && !grep { !matches($got[$_], $said[$_]) } 0 .. $#said;
    ok $ok, "$REFERENCE line $line runs, and prints what its comments say"
        or diag "exit status $status, and on STDERR:\n$stderr",
        "printed:\n", map({ "    $_\n" } @got), "its comments say:\n",
        map { "    $_\n" } @said;
}

for my $example (pod_examples($README)) {
    my($line, $code) = @$example;
    # Stand-ins, such as users(), are undeclared, and the examples follow
    # on from each other, so only syntax and the parts' prototypes are
    # checked.
    my($status, undef, $stderr) = run(
              "$preamble\nno strict qw(vars subs);\nno warnings;\n"
            . "sub {\n#line $line \"$README\"\n$code};\n",
        '-c',
    );
    is [$status, $stderr =~ s( ^ example\.pl\ syntax\ OK \n )()xmr], [0, ''],
        "$README line $line compiles";
}

done_testing;

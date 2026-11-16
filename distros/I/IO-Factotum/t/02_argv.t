use v5.16;
use warnings;
use Test::More 0.98;
use File::Temp qw(tempdir);
use File::Spec;

my $dir = tempdir(CLEANUP => 1);

sub put {
    my($name, $text) = @_;
    open my $fh, '>', "$dir/$name" or die "$name: $!";
    print $fh $text;
    close $fh;
    "$dir/$name";
}

put 'f1', "one\ntwo\n";
put 'f2', "three\n";
put 'empty', "";

# Run a script, which reads by <>, with an uppercasing converter for
# every file and ARGV tied.  It runs in the directory of the files.
my $lib = File::Spec->rel2abs('lib');
sub run {
    my($body, @args) = @_;
    my $script = put 'script.pl', <<"END";
use IO::Factotum;
IO::Factotum::register(match => qr/./, command => ['perl', '-pe', '\$_ = uc']);
IO::Factotum::tie_argv();
\$| = 1;
$body
END
    my $args = join ' ', @args;
    scalar qx{cd "$dir" && $^X -I"$lib" script.pl $args 2>&1};
}

is run('while (<>) { print "$ARGV: $_" }', 'f1 f2'),
    "f1: ONE\nf1: TWO\nf2: THREE\n",
    'argv: while (<>)';

is run('use Getopt::Long; GetOptions("x" => \my $x); print "x=$x\n";' .
       'while (<>) { print "$ARGV: $_" }', '-x f1 f2'),
    "x=1\nf1: ONE\nf1: TWO\nf2: THREE\n",
    'argv: after Getopt::Long';

is run('while (<>) { print "$ARGV: $_" }', '< f2'),
    "-: three\n",
    'argv: stdin is not converted';

is run('my @l = <>; print scalar @l, ":", @l', 'f1 f2'),
    "3:ONE\nTWO\nTHREE\n",
    'argv: list context';

is run('while (<>) { print "$.:$_" }', 'f1 f2'),
    "1:ONE\n2:TWO\n3:THREE\n",
    'argv: line numbers go on';

is run('while (<>) { print "$.:$_"; close ARGV if eof }', 'f1 f2'),
    "1:ONE\n2:TWO\n1:THREE\n",
    'argv: close ARGV if eof resets the line number';

is run('while (<>) { print eof() ? "last:$_" : "" }', 'f1 f2'),
    "last:THREE\n",
    'argv: eof()';

is run('while (<>) { print eof() ? "last:$_" : "" }', 'f1 f2 empty'),
    "last:THREE\n",
    'argv: eof() with an empty file at the end';

is run('while (<>) { print "$ARGV: $_" }', 'f1 none f2'),
    "f1: ONE\nf1: TWO\nCan't open none: No such file or directory\nf2: THREE\n",
    'argv: a file which can not be opened is skipped';

is run('IO::Factotum::tie_argv(); while (<>) { print }', 'f2'),
    "THREE\n",
    'argv: tie_argv twice';

done_testing;

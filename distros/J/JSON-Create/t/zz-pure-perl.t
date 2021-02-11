# Test the pure-Perl version of the module using the same tests as the
# XS version.

use warnings;
use strict;
use FindBin '$Bin';
use Config '%Config';
use Cwd qw(realpath);
use Test::More;
use File::Basename 'dirname';

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

if ($ENV{JSONCreatePP}) {
    # What this test does is to run all the tests in t/, except with
    # the XS switched off, so if the environment variable is true, we
    # are running this test from itself, so quit.
    plan 'skip_all',
	"Skipping PP subtests, $0 is already running in Pure-Perl mode";
}

$ENV{JSONCreatePP} = 1;
my $dir = "$Bin/..";
chdir $dir or die $!;
my $prove = _prove_path ();
if (! $prove) {
    plan skip_all => "_prove_path () failed";
}
my $status = system ("$prove -I $dir/blib/arch -I $dir/blib/lib $dir/t/*.t");
ok ($status == 0, "PP passed tests");
done_testing ();

# https://github.com/benkasminbullock/json-create/issues/46
# https://github.com/eserte/Doit/blob/bb6e6c840fdfe23175ce70ec35505721ec92a2b4/Build.PL#L970-L988

sub _prove_path {
    my @directory_candidates = ($Config{bin}, dirname(realpath $^X));
    my @basename_candidates = ('prove', "prove$Config{version}");
    my @candidates = map {
	my $basename = $_;
	map {
	    "$_/$basename";
	} @directory_candidates;
    } @basename_candidates;
    if ($^O eq 'MSWin32') {
	unshift @candidates, map { "$_.bat"} @candidates;
    }
    for my $candidate (@candidates) {
	if (-x $candidate) {
	    return $candidate;
	}
    }
    return undef;
}

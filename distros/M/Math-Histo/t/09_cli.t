use strict;
use warnings;
use Test2::V0;
use Math::Histo;
use Math::Histo::CLI;
use File::Temp qw(tempdir);
use File::Spec;

my $tmpdir = tempdir(CLEANUP => 1);
my $hfile = File::Spec->catfile($tmpdir, 'test.histo');

# Create and save test histogram
{
    my $h = Math::Histo->new(bins => 20, min => 0.0, max => 100.0);
    $h->fill_n([10.0, 25.0, 50.0, 75.0, 90.0]);
    $h->write_file($hfile);
}

sub run_cli {
    open my $oldout, '>&', STDOUT or die "Cannot dup STDOUT: $!";
    open my $olderr, '>&', STDERR or die "Cannot dup STDERR: $!";
    open STDOUT, '>', File::Spec->devnull() or die "Cannot redirect STDOUT: $!";
    open STDERR, '>', File::Spec->devnull() or die "Cannot redirect STDERR: $!";
    my $ret = eval { Math::Histo::CLI->run(@_) };
    my $err = $@;
    open STDOUT, '>&', $oldout or die "Cannot restore STDOUT: $!";
    open STDERR, '>&', $olderr or die "Cannot restore STDERR: $!";
    die $err if $err;
    return $ret;
}

subtest 'CLI version and help output' => sub {
    my $st_help = run_cli('--help');
    is($st_help, 0, 'CLI --help returns 0');

    my $st_ver = run_cli('--version');
    is($st_ver, 0, 'CLI --version returns 0');
};

subtest 'CLI subcommands in-process' => sub {
    # Test stats
    my $st_stats = run_cli('stats', $hfile);
    is($st_stats, 0, 'CLI stats command returns 0');

    # Test plot
    my $st_plot = run_cli('plot', '--style=ascii', $hfile);
    is($st_plot, 0, 'CLI plot command returns 0');

    # Test sparkline
    my $st_spark = run_cli('plot', '--sparkline', $hfile);
    is($st_spark, 0, 'CLI plot sparkline returns 0');

    # Test fit
    my $st_fit = run_cli('fit', '--model=gaussian', $hfile);
    is($st_fit, 0, 'CLI fit command returns 0');

    # Test cmp against itself
    my $st_cmp = run_cli('cmp', $hfile, $hfile);
    is($st_cmp, 0, 'CLI cmp command returns 0');
};

subtest 'CLI error handling' => sub {
    my $st_unknown = run_cli('nonexistent_command');
    isnt($st_unknown, 0, 'Unknown command returns non-zero status');

    my $st_bad_file = run_cli('stats', 'nonexistent_file_xyz.histo');
    isnt($st_bad_file, 0, 'Non-existent file returns non-zero status');
};

done_testing;

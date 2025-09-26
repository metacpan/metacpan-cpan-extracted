use v5.40;
use Test2::V0;
use Path::Tiny;

require Minima::Setup;

my $dir     = Path::Tiny->tempdir;
my $app_dir = $dir->child('A')->mkdir;
my $psgi    = $app_dir->child('app.psgi');

$psgi->spew('use Minima::Setup ; 1');

do $psgi or die $@;

{
    no warnings 'once';
    is(
        path($Minima::Setup::base)->basename,
        'A',
        'sets base to .psgi parent directory'
    );
}

done_testing;

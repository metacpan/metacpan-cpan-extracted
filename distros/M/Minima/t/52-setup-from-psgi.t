use v5.40;
use Test2::V0;
use Path::Tiny;

our $original_caller = 1;
BEGIN {
    *CORE::GLOBAL::caller = sub { 
        $original_caller ? caller(@_) : ( undef, '/A/app.psgi' ) };
}

require Minima::Setup;

my $dir = Path::Tiny->tempdir;
chdir $dir;

# Detect .psgi caller
my $base_config = $dir->child('base.pl');
$base_config->spew('{ }');
$original_caller = 0;
Minima::Setup->import('base.pl');

{
    no warnings 'once';
    like(
        path($Minima::Setup::base)->basename,
        'A',
        'sets base to .psgi parent directory'
    );
}

chdir;

done_testing;

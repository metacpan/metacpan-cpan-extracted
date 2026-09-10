use v5.38;
use Test::More;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage"
    if $@;

my @command_modules = qw(
    Luv::CLI::Command::Init
    Luv::CLI::Command::Add
    Luv::CLI::Command::Remove
    Luv::CLI::Command::Build
    Luv::CLI::Command::List
    Luv::CLI::Command::Search
    Luv::CLI::Command::Update
);

my %trustme = ( trustme =>
        [qr/^(execute|opt_spec|abstract|usage_desc|validate_args|render)$/] );

plan tests => 1 + scalar(@command_modules);

pod_coverage_ok('Luv::CLI');
pod_coverage_ok( $_, \%trustme ) for @command_modules;

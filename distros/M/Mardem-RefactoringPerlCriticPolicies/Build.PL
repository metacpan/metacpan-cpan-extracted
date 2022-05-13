#!perl

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Module::Build;

Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    'module_name'         => 'Mardem::RefactoringPerlCriticPolicies',
    'dist_abstract'       => 'Some Perl::Critic::Policies to search for needed refactoring',
    'license'             => 'Perl_5',
    'dist_author'         => q{Markus Demml <mardem@cpan.com>},
    'dist_version_from'   => 'lib/Mardem/RefactoringPerlCriticPolicies.pm',
    'release_status'      => 'stable',
    'configure_requires' => {
        'Module::Build' => '0.4004',
    },
    'test_requires' => {
        'Test::More' => 0,
        'English' => 0,
        'Test::CheckManifest' => 0,
        'Test2::V0' => 0,
        'Test2::Tools::Exception' => 0,
        'Cwd' => 0,
        'Path::This' => 0,
        'Test::Pod' => 0,
        'Test::Pod::Coverage' => 0,
         'Pod::Coverage' => 0,
    },
    'requires' => {
        'perl' => 5.010,
        'Exporter' => 0,
        'Readonly' => 0,
        'List::Util' => 0,
        'Perl::Critic' => 0,
        'Perl::Critic::Policy' => 0,
        'Perl::Critic::Utils' => 0,
        'Perl::Critic::Utils::McCabe' => 0,
    },
    'recommends' => {

    },
    'add_to_cleanup'     => [ 'Mardem-RefactoringPerlCriticPolicies-*' ],
);

$builder->create_build_script();

use strict;
use warnings;

use Test::Most tests => 1;

use Module::Build::WithXSpp;
use Data::Dumper;

chdir('t/01-vector_of_vectors');

my $builder = Module::Build::WithXSpp->new(
    module_name  => 'test_vector_of_vectors',
    license      => 'perl',
    dist_version => '0.01',

#pm_files => {'t/01-vector_of_vectors/lib/test_vector_of_vectors.pm' => 'lib/test_vector_of_vectors.pm'},
    'build_requires' => {
        'ExtUtils::Typemaps::Default' => '1.05',
        'ExtUtils::XSpp'              => '0.18',
        'Module::Build'               => '0.4211',
        'Test::More'                  => '0'
    },
    'configure_requires' => {
        'ExtUtils::CppGuess'      => '0.07',
        'Module::Build'           => '0.4211',
        'Module::Build::WithXSpp' => '0.13'
    },
    extra_compiler_flags  => [qw(-std=c++11)],
    extra_typemap_modules => {

        #'ExtUtils::Typemaps::Default' => '1.05',
        'ExtUtils::Typemaps::STL::Extra' => '0',
    },
    cpp_source_dirs => [qw(src)],
    extra_xs_dirs   => [qw(xsp)]

);

$builder->create_build_script();
$builder->dispatch('build');

push @INC, './blib/arch', './blib/lib';
use Module::Load;
load 'test_vector_of_vectors';
my $array = [ [ 1, 2, 3 ], [ 4, 5, 6 ] ];

diag( Dumper( test_vector_of_vectors::check_vector_of_vectors($array) ) );
is_deeply( $array, test_vector_of_vectors::check_vector_of_vectors($array) );

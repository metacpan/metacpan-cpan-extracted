use 5.008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'LaTeX::Table',
    license             => 'perl',
    dist_author         => '<limaone@cpan.org>',
    dist_version_from   => 'lib/LaTeX/Table.pm',
    requires => {
        'perl'           => '5.8.0', 
        'English'        => 0,
        'Moose'     => 0.76,
        'MooseX::FollowPBP'    => 0.03,
        'Module::Pluggable'    => 0,
        'Scalar::Util'   => 0,
        'Carp'           => 0,
        'version'        => 0,
        'Template'       => 0,
        'Cwd'            => 0,
    },
    build_requires => {
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
        'File::Spec'       => 0,
    }, 
    recommends => {
        'Text::CSV'      => 0,
        'LaTeX::Driver'  => 0,
        'LaTeX::Encode'  => 0,
        'Getopt::Long'   => 0,
        'Number::Format' => 0,
        'autodie'        => 0,
    },    
    script_files        => [ 'bin/csv2pdf', 'bin/ltpretty' ], 
    meta_merge => {
        resources => {
            repository => 'http://github.com/lima1/p5-latex-table',
        },
    },
    add_to_cleanup      => [ 'LaTeX-Table-*' ],
);

$builder->create_build_script();

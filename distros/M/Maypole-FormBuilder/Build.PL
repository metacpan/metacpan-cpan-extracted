use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Maypole::FormBuilder',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Maypole/FormBuilder.pm',
    requires => {
        'Test::More' => 0,
        'Class::DBI' => 0,
        'Class::DBI::Loader' => 0,
        'Class::DBI::AbstractSearch' => 0,
        'Class::DBI::Plugin::RetrieveAll' => 0,
        
        'Class::DBI::Pager' => 0,
        
        'Class::DBI::FormBuilder' => 0.46,
        
        'Maypole::Plugin::QuickTable' => 0.421,
        
        'Maypole::Plugin::LinkTools' => 0.2,
        'Maypole::Plugin::Session' => 0.2,
        
        'Maypole' => 2.10,
        
        'NEXT' => 0,
        'UNIVERSAL::require' => 0,
        'HTML::TreeBuilder' => 0,
        'URI' => 0,
        'URI::QueryParam' => 0,
        'List::Util' => 0,
        #'Class::Inspector' => 0,
        
    },
    add_to_cleanup      => [ 'Maypole-FormBuilder-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();

use strict;
use warnings;
use Module::Build;

# bootstrap - so we can load Devel::Maypole before installing it
use lib 'lib';

# We use Devel::Maypole to install its own templates
use Devel::Maypole qw/ :install /;

my $builder = Module::Build->new(
    module_name         => 'Devel::Maypole',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Devel/Maypole.pm',
    requires => {
        'Test::More' => 0,
        'Test::File' => 0,
        'Test::Exception' => 0,
        'Maypole::Config' => 0,
        'File::Temp' => 0,
        'File::Slurp' => 0,
        'Data::Dumper' => 0,
        'DBI' => 0,
        'Test::WWW::Mechanize::Maypole' => 0,
        'Sysadm::Install' => 0,
        'File::Copy::Recursive' => 0,
        'Path::Class' => 0,
        'UNIVERSAL::require' => 0,
    },
    add_to_cleanup      => [ 'Devel-Maypole*' ],
    create_makefile_pl  => 'passthrough',
);

# install templates
print <<MSG;
We are about to install Maypole resources on your system. 
This operation will fail if the user we are running as 
does not have write permission to the chosen target directories. 

MSG

my %sources = ( templates   => 't/templates',
                yaml_config => 'config',
                ddl         => 'sql/ddl',
                data        => 'sql/data',
                );
                
foreach my $what ( keys %sources )
{
    my $cfg = $builder->config_data( $what ) || {};
        
    $cfg->{default} =   
        install( $what, 'Devel::Maypole', $sources{ $what }, 'default' );
    
    $builder->config_data( $what => $cfg );
}

$builder->create_build_script();


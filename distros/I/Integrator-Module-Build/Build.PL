use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Integrator::Module::Build',
    license             => 'perl',
    dist_author         => 'Francois Perron <fxfx@cydone.com>',
    dist_version_from   => 'lib/Integrator/Module/Build.pm',
    requires		=> {
	'perl'			=> '>= 5.8.8',
	'Test::Harness'		=> '2.64',
	'YAML'			=> 0,
	'Test::Pod'		=> 0,
	'Devel::Symdump'	=> 0,
	'Test::Pod::Coverage'	=> 0,
	'Test::Cmd'		=> 0,
	'XML::NamespaceSupport' => 0,
	'XML::SAX'		=> 0,
	'XML::SAX::Expat'	=> 0,
	'XML::Parser'		=> 0,
	'XML::Simple'		=> 0,
	'Crypt::SSLeay'		=> 0,
	'Term::ReadKey'		=> 0,
	'Data::UUID'		=> 0,
    },
    build_requires => {
	 'Module::Starter'	=> 0,
	 'URI'			=> 0,
	 'Compress::Zlib'	=> 0,
	 'HTML::Tagset'		=> 0,
	 'HTML::Parser'		=> 0,
		'LWP::UserAgent'	=> 0,
	 'Test::TAP::Model'	=> '0.06666', # !!!!!!!!! WITH straps-patch !!!!!!!!!!!
	 'Method::Alias'	=> 0,
    },
    add_to_cleanup      => [ 'Integrator-Module-Build-*' ],
#    sign		=> 1,
);

$builder->create_build_script();


#Dependency list:
#started on perl 5.8.4
#tested with  perl 5.8.5
#developped with perl 5.8.7 
#now needs perl 5.8.8 because of various library issues...

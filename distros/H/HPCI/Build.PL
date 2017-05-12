# Safe Perl
use strict;
use autodie;

use Module::Build;


my $builder = Module::Build->new(
    module_name         => 'HPCI',
    license             => 'perl',
	dist_author         => [
		'Boutros Lab Software Engineering  <BoutrosLabSoftware@oicr.on.ca>',
		'John Macdonald  <jmacdonald@oicr.on.ca>',
	],

    dist_version_from   => 'lib/HPCI.pm',
    dist_abstract       => 'Interface modules for high performance computing on compute clusters.',

    # Modules required to build this module
    configure_requires => {
        'Module::Build'                  => 0,
    },
    build_requires => {
        'Test::More'                     => '0.10',
		'Test::Exception'                => 0,
        'File::pushd'                    => 0,
        'File::Slurp'                    => 0,
        'File::Spec'                     => 0,
        'File::Temp'                     => 0,
        'Module::Build'                  => 0,
    },

    # Modules required to use this module
    requires => {
		'Carp'                           => 0,
		'Data::Dumper'                   => 0,
		'DateTime'                       => 0,
		'File::Path'                     => 0,
        'File::ShareDir'                 => 0,
        'Log::Log4perl'                  => 0,
        'Log::Log4perl::Appender'        => 0,
        'Log::Log4perl::Level'           => 0,
        'Module::Load'                   => 0,
        'Module::Load::Conditional'      => 0,
        'Moose'                          => 0,
        'Moose::Role'                    => 0,
        'Moose::Util::TypeConstraints'   => 0,
        'MooseX::ClassAttribute'         => 0,
        'MooseX::Role::Parameterized'    => 0,
        'MooseX::Types::Path::Class'     => 0,
        'MooseX::Params::Validate'       => 0,
        'Params::Validate'               => 0,
		'POSIX'                          => 0,
		'Time::HiRes'                    => 0,
		'Try::Tiny'                      => 0,
		'autodie'                        => 0,
        'namespace::autoclean'           => 0,
		# 'Text::Xslate'                   => 0,
    },
);

$builder->create_build_script();

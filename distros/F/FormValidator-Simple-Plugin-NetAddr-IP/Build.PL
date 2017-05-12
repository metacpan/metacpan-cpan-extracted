use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'FormValidator::Simple::Plugin::NetAddr::IP',
    license             => 'perl',
    dist_author         => 'Eric Hacker <hacker@cpan.org>',
    dist_abstract		=> 'IP Address validation',
    dist_version_from   => 'lib/FormValidator/Simple/Plugin/NetAddr/IP.pm',
    requires => {
		'FormValidator::Simple'		=> '0',
		'NetAddr::IP'		        => '3',
    	},
    create_makefile_pl => 'passthrough',
);

$builder->create_build_script();



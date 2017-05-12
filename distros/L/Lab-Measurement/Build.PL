#!/usr/bin/perl

use strict;
use utf8;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Lab::Measurement',
    dist_abstract     => 'Test and measure with Perl',
    license           => 'perl',
    requires          => {
	'perl'               => '5.14.0',
	'PDL'                => '2.007',
        'IO::Socket::Timeout'=> '0.32',
	'aliased'            => 0,

	# Module::Load in perl <= 5.18 does not have autoload function.
	'Module::Load'       => '0.26',
	
	'Try::Tiny'          => '0.22',
	'Moose'              => '2.1213',
	'MooseX::Params::Validate' => '0.18',
	'namespace::autoclean'      => '0.20',
	'Class::Method::Modifiers' => '2.11',
	'Role::Tiny'               => '1.003004',
	'YAML::XS'                 => '0.41',
	'Exception::Class'   => '1.0',
        'Class::ISA'         => 0,
        'Hook::LexWrap'      => 0,
        'Time::HiRes'        => 0,
        'XML::DOM'           => 0,
        'XML::Generator'     => 0,
        'XML::Twig'          => 0,
        'Data::Dumper'       => 0,
        'Encode'             => 0,
        'Cwd'                => 0,
        'File::Basename'     => 0,
        'File::Copy'         => 0,
        'encoding::warnings' => 0,
        'Term::ReadKey'      => '2.30',
        'Clone'              => '0.31',
	'Module::Build'      => '0',
	'YAML'               => 0,
	'List::MoreUtils'    => 0,
	'Statistics::Descriptive' => 0,
    },
    test_requires => {
	'File::Slurper' => 0,
	'Text::Diff' => 0,
	'Test::File' => 0,
	'Test::Fatal' => '0.012'
    },
    conflicts         => {
        'Lab::Instrument'    => '< 2.91',
        'Lab::Tools'         => '< 2.91',
    },
    script_files => [ 'scripts/lab-makefilelist.pl',
	'scripts/lab-makemakefile.pl',
	'scripts/lab-plotter.pl', 
	'scripts/lab-update.pl', 
	'lib/Lab/XPRESS/Xpression.pl',
	'lib/Lab/XPRESS/Xpression/bin/vieWx.pl' ],
    create_readme     => 0,
    dist_author       => ['Andreas K. Hüttel <mail@akhuettel.de>',
			  'Christian Butschkow <christian.butschkow@physik.uni-r.de>',
			  'Alexei Iankilevitch <alexei.iankilevitch@physik.uni-r.de>', 
			  'Simon Reinhardt <simon.reinhardt@stud.uni-regensburg.de>',
			  'Charles E. Lane <lane@duphy4.physics.drexel.edu>'
    ],
    recursive_test_files => 1,
    meta_merge        => {
        resources       => {
            homepage      => 'http://www.labmeasurement.de/',
            bugtracker    => 'https://github.com/lab-measurement/lab-measurement/issues',
            MailingList   => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-measurement-users',
            repository    => 'https://github.com/lab-measurement/lab-measurement.git',
        }
    },
);
$build->create_build_script;

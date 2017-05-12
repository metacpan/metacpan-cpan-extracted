use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FSpot::DbTool',
    AUTHOR              => q{Robin Clarke <perl@robinclarke.net>},
    VERSION_FROM        => 'lib/FSpot/DbTool.pm',
    ABSTRACT_FROM       => 'lib/FSpot/DbTool.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
		'Cwd'						   => 0,
		'Data::Dumper'                 => 0,
		'DBD::SQLite'                  => 0,
		'DBI'                          => 0,
		'File::Copy'                   => 0,
		'File::HomeDir'                => 0,
		'File::Spec::Functions'        => 0,
	    'File::Util'                   => 0,
		'Log::Log4perl'                => 0,
		'Moose'                        => 0,
		'Moose::Role'                  => 0,
		'Moose::Util::TypeConstraints' => 0,
		'MooseX::Params::Validate'     => 0,
		'MooseX::StrictConstructor'    => 0,
        'Test::More'                   => 0,
		'YAML::Any'                    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FSpot-DbTool*' },
);

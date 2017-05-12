use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Google::Fusion',
    AUTHOR              => q{Robin Clarke <perl@robinclarke.net>},
    VERSION_FROM        => 'lib/Google/Fusion.pm',
    ABSTRACT_FROM       => 'lib/Google/Fusion.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES	=> [ 'bin/pfusion' ],
    PREREQ_PM => {
	'Carp'				=> 0,
	'Encode'			=> 0,
	'File::HomeDir'			=> 0,
	'IO::String'			=> 0,
	'LWP::Protocol::https'		=> 0,
	'LWP::UserAgent'		=> 0,
	'Moose'				=> 0,
	'Moose::Util::TypeConstraints'	=> 0,
	'MooseX::Params::Validate'	=> 0,
	'Net::OAuth2::Moosey::Client'	=> 0.02,
	'Test::More'			=> 0,
	'Text::CSV'			=> 0,
	'Text::Table'			=> 0,
	'URL::Encode'			=> 0,
	'YAML'				=> 0,
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
     (META_ADD => {
      resources => {
      homepage   => 'https://github.com/robin13/Google-Fusion',
      repository => 'https://github.com/robin13/Google-Fusion',
      bugtracker => 'https://github.com/robin13/Google-Fusion/issues',
      },
      })
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Google-Fusion-*' },
);

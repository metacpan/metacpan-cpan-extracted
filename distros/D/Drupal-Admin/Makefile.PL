use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Drupal::Admin',
    AUTHOR              => 'Dan Urist <durist@frii.com>',
    VERSION_FROM        => 'lib/Drupal/Admin.pm',
    ABSTRACT_FROM       => 'lib/Drupal/Admin.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Log::Log4perl' => 0,
	'Moose' => 0,
	'MooseX::Log::Log4perl::Easy' => 0,
	'WWW::Mechanize' => 0,
	'WWW::Mechanize::TreeBuilder' => 0,
	'Pod::Usage' => 0,
	'File::Type' => 0,
	'Getopt::Long' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Drupal-Admin-*' },
);

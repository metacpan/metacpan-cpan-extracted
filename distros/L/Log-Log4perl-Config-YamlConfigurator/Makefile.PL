use strict;
use warnings;

use Config                        qw( %Config );
use ExtUtils::MakeMaker::CPANfile qw( WriteMakefile );

my %WriteMakefileArgs = (
  NAME             => 'Log::Log4perl::Config::YamlConfigurator',
  AUTHOR           => 'Sven Willenbuecher <sven.willenbuecher@gmx.de>',
  VERSION_FROM     => 'lib/Log/Log4perl/Config/YamlConfigurator.pm',
  ABSTRACT_FROM    => 'lib/Log/Log4perl/Config/YamlConfigurator.pod',
  LICENSE          => 'Perl_5',
  MIN_PERL_VERSION => '5.006',
  META_MERGE       => {
    'meta-spec' => { version => 2 },
    provides    => {
      'Log::Log4perl::Config::YamlConfigurator' => {
        file    => 'lib/Log/Log4perl/Config/YamlConfigurator.pm',
        version => 'v1.0.0',
      },
    },
    resources => {
      repository => {
        type => 'git',
        url  => 'git://github.com/XSven/Log-Log4perl-Config-YamlConfigurator.git',
        web  => 'https://github.com/XSven/Log-Log4perl-Config-YamlConfigurator',
      },
      bugtracker => {
        web => 'https://github.com/XSven/Log-Log4perl-Config-YamlConfigurator/issues',
      },
    },
  },
  clean     => { FILES                => 'Log-Log4perl-Config-YamlConfigurator-* cover_db' },
  dist      => { COMPRESS             => 'gzip -9f', SUFFIX => 'gz', },
  realclean => { FILES                => 'local' },
  test      => { RECURSIVE_TEST_FILES => 1 },
);

require './maint/AuthorExtensions.pl'
  unless ( $Config{ osname } =~ m/\A(?:freebsd|openbsd|solaris)\z/ or exists( $ENV{ MAKELEVEL } ) );

WriteMakefile( %WriteMakefileArgs );

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'A plugin for Log::Handler using Log::Hander::Output::DBI',
 ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST Log-Handler-Plugin-DBI-*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'Log-Handler-Plugin-DBI',
 NAME      => 'Log::Handler::Plugin::DBI',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	 Carp                      => 1.20,
	 Config::Plugin::Tiny      => 1.01,
	 DBD::SQLite               => 1.35,
	 DBIx::Admin::CreateTable  => 2.07,
	 DBIx::Connector           => 0.47,
	 Hash::FieldHash           => 0.12,
	 Log::Handler::Output::DBI => 0.11,
	 strict                    => 1.03,
	 Test::More                => 0.94,
	 Test::Pod                 => 1.44,
	 vars                      => 1.01,
	 warnings                  => 1.03,
 },
 VERSION_FROM => 'lib/Local/Logger.pm',
);

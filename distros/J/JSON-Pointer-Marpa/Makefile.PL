use strict;
use warnings;

use Config                        qw( %Config );
use File::Spec::Functions         qw( catfile );
use ExtUtils::MakeMaker::CPANfile qw( WriteMakefile );

my @main_module_namespace = qw( JSON Pointer Marpa );
my $version               = '1.0.2';
my $release_status        = 'stable';                   # transition: unstable => testing => stable

my $distname            = join '-',  @main_module_namespace;
my $main_module         = join '::', @main_module_namespace;
my $main_module_file    = catfile( @main_module_namespace ) . '.pm';
my $main_module_podfile = catfile( @main_module_namespace ) . '.pod';
my %WriteMakefileArgs   = (
  NAME             => $main_module,
  AUTHOR           => 'Sven Willenbuecher <sven.willenbuecher@gmx.de>',
  VERSION_FROM     => catfile( 'lib', $main_module_file ),
  ABSTRACT_FROM    => catfile( 'lib', $main_module_podfile ),
  LICENSE          => 'Perl_5',
  MIN_PERL_VERSION => '5.10.1',
  META_MERGE       => {
    'meta-spec' => { version => 2 },
    provides    => {
      $main_module => {
        file    => catfile( 'lib', $main_module_file ),
        version => $version
      },
      join( '::', $main_module, 'Semantics' ) => {
        file => 'lib/JSON/Pointer/Marpa/Semantics.pm',
      }
    },
    resources => {
      repository => {
        type => 'git',
        url  => "git://github.com/XSven/$distname.git",
        web  => "https://github.com/XSven/$distname"
      },
      bugtracker => {
        web => "https://github.com/XSven/$distname/issues"
      }
    }
  },
  clean     => { FILES                => "$distname* cover_db" },
  dist      => { TARFLAGS             => 'cf', COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
  realclean => { FILES                => 'local' },
  test      => { RECURSIVE_TEST_FILES => 1 }
);

no warnings qw( void );
caller() ? \%WriteMakefileArgs : WriteMakefile( %WriteMakefileArgs )

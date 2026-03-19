use strict;
use warnings;

use ExtUtils::MM          ();
use File::Spec::Functions qw( catfile );

my $git_base_url = 'https://codeberg.org/XSven';
my $distname     = 'Getopt-Guided';

my @main_module_namespace = split /-/, $distname;
my $main_module           = join '::', @main_module_namespace;
my $main_module_file      = catfile( 'lib', @main_module_namespace ) . '.pm';
my $main_module_podfile   = catfile( 'lib', @main_module_namespace ) . '.pod';
# We are not using
# VERSION_FROM  => $main_module_file
# because we have to set the main module version in META_MERGE/provides too
my $main_module_version = MM->parse_version( $main_module_file );

my %att = (
  NAME          => $main_module,
  AUTHOR        => 'Sven Willenbuecher <sven.willenbuecher@gmx.de>',
  VERSION       => $main_module_version,
  ABSTRACT_FROM => $main_module_podfile,
  # Another valid license string is "restricted"
  # https://metacpan.org/pod/CPAN::Meta::Spec#license
  LICENSE          => 'perl_5',
  MIN_PERL_VERSION => '5.010000',
  DISTNAME         => $distname,
  EXE_FILES        => [ glob( join( ' ', map { catfile( $_, '*' ) } qw( bin script ) ) ) ],
  META_MERGE       => {
    'meta-spec' => { version => 2 },
    provides    => {
      $main_module => {
        file    => $main_module_file,
        version => $main_module_version
      }
    },
    resources => {
      repository => {
        type => 'git',
        url  => "$git_base_url/$distname.git",
        web  => "$git_base_url/$distname"
      },
      bugtracker => {
        web => "$git_base_url/$distname/issues"
      }
    }
  },
  # Check ExtUtils::MakeMaker Changes
  NORECURS     => 1,
  NO_PERLLOCAL => 1,
  clean        => { FILES                => "$distname*" },
  dist         => { TARFLAGS             => 'cf', COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
  realclean    => { FILES                => 'cover_db local' },
  test         => { RECURSIVE_TEST_FILES => 1 }
);

if ( caller() ) {
  *WriteMakefile = sub {
    my %args = @_;
    @ARGV ? [ @args{ @ARGV } ] : \%args
  }
} else {
  require ExtUtils::MakeMaker::CPANfile;
  ExtUtils::MakeMaker::CPANfile->import
}
WriteMakefile( %att )

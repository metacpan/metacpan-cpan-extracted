#! perl

use strict;
use warnings;

exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.026000;

use ExtUtils::MakeMaker 7.54;

my $version = MM->parse_version('lib/JSON/Relaxed/Parser.pm');

# For binaries/scripts.
my @bins; # = qw( prog );

my %makemaker =
  ( 'ExtUtils::MakeMaker' => 7.54 );

my %prereq =
  ( 'Object::Pad'         => 0.800,
  );

my %w =
( NAME                => 'JSON::Relaxed',
  AUTHOR              => 'Johan Vromans <jv@cpan.org>',
  VERSION             => $version,
  ABSTRACT_FROM       => 'lib/JSON/Relaxed.pm',
  LICENSE             => 'perl_5',
  PL_FILES            => {},
  MIN_PERL_VERSION    => '5.026000',

  @bins == 0 ? () : (
    EXE_FILES         => [ map { "script/$_" } @bins ],
    PL_FILES          => {
			   'script/pp.PL' => [ map { "script/$_" } @bins ]
			 },
  ),

  PREREQ_PM => {
    %makemaker,
    %prereq,
  },

  CONFIGURE_REQUIRES => {
    %makemaker,
  },

#  BUILD_REQUIRES => {
#  },

  TEST_REQUIRES  => {
    'Test::More'	=> 0,
    'FileHandle'	=> 0,
    'File::LoadLines'	=> 1,
    'JSON::PP'		=> 4,
    %prereq,
  },

  META_MERGE => {
    'meta-spec'  => { version => 2 },
    resources    => {
      license    => [ "https://dev.perl.org/licenses/" ],
      homepage   => 'https://github.com/sciurius/perl-JSON-Relaxed',
      repository => {
	url => 'git://github.com/sciurius/perl-JSON-Relaxed.git',
	web => 'https://github.com/sciurius/perl-JSON-Relaxed',
	type => 'git',
      },
      bugtracker => {
        web => "https://github.com/sciurius/perl-JSON-Relaxed/issues",
        mailto => 'jv@cpan.org',
      },
    },
     provides => {
	 "JSON::Relaxed"
		  => { file => "lib/JSON/Relaxed.pm",
		       version => $version },
	 "JSON::Relaxed::Parser"
		  => { file => "lib/JSON/Relaxed/Parser.pm",
		       version => $version },
	 "JSON::Relaxed::ErrorCodes"
		  => { file => "lib/JSON/Relaxed/ErrorCodes.pm",
		       version => $version },
     },
     no_index => {
         package => [
	    "JSON::Relaxed::Parser::Token",
	    "JSON::Relaxed::Parser::String",
	    "JSON::Relaxed::Parser::String::Quoted",
	    "JSON::Relaxed::Parser::String::Unquoted",
	 ],
     }
  },
);

WriteMakefile(%w);

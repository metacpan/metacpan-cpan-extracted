#! perl

# Makefile generator for HarfBuzz::Shaper

# Author          : Johan Vromans
# Created On      : Sat Jan 17 21:40:08 2026
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jan 19 20:57:19 2026
# Update Count    : 28
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use Config;
use PkgConfig;

my $master = 'lib/HarfBuzz/Shaper.pm';
my $version = MM->parse_version($master);

# Package name.
my $my_package = 'HarfBuzz::Shaper';
# Program name and version.
my $my_name = 'Makefile.PL';
my $my_version = $version;

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

my %args = (

  NAME             => 'HarfBuzz::Shaper',
  AUTHOR           => 'Johan Vromans <jv@cpan.org>',
  VERSION          => $version,
  ABSTRACT_FROM    => $master,
  LICENSE          => 'perl_5',
  PL_FILES         => {},
  LIBS             => [],
  INC              => '-I.',
  MIN_PERL_VERSION => '5.010001',

  PREREQ_PM => {
      'ExtUtils::MakeMaker' => 6.46, # for META_MERGE, LICENSE
      'Archive::Tar'        => 0,
  },

  TEST_REQUIRES  => {
      'Test::More'          => 0,
  },

  META_MERGE => {
    resources    => {
      repository => {
	type => 'git',
	web  => 'https://github.com/sciurius/perl-HarfBuzz-Shaper',
	url  => 'https://github.com/sciurius/perl-HarfBuzz-Shaper.git',
      },
      bugtracker => {
	web  => "https://github.com/sciurius/perl-HarfBuzz-Shaper/issues",
      },
    },
    'meta-spec' => {
      version => '2',
      url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
    },
    provides => {
      "HarfBuzz::Shaper"
		   => { file => "lib/HarfBuzz/Shaper.pm",
			version => $version },
    },

    no_index => {
      directory => [
		"inc", "t", "harfbuzz",
      ],
    },
  }
);

################ The Process ################

my %po;
if ( $^O =~ /darwin/ ) {
    for ( qw( /opt/homebrew/lib/pkgconfig/ ) ) {
	next unless -d $_;
	push( @{$po{search_path}}, $_ );
    }
}

my $ok = PkgConfig->find( "harfbuzz", %po );
if ( $ok->errmsg ) {
    die($ok->errmsg);
}

my $vv = $ok->pkg_version;
if ( $vv =~ /^(\d+)\.(\d+)/ ) {
    die("HarfBuzz library $vv found, but too old (need at least 1.7.0\n")
      if $1 < 1 || ( $1 == 1 && $2 < 7 );
}

my $res = $ok->get_ldflags;
if ( $res ) {
    $args{LIBS} = [ $res ];
}

$res = $ok->get_cflags;
if ( $res  ) {
    $args{INC} = $res;
}

warn("Using harfbuzz library $vv\n") if $verbose;

# Write the Makefile.
WriteMakefile(%args);

exit 0;

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'ident'	=> \$ident,
		     'verbose+'	=> \$verbose,
		     'quiet'	=> sub { $verbose = 0 },
		     'trace'	=> \$trace,
		     'help|?'	=> \$help,
		     'debug'	=> \$debug,
		    ) or $help )
    {
	app_usage(2);
    }
    app_ident() if $ident;
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $^X $0 [options]
   --ident		shows identification
   --help		shows a brief help message and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}

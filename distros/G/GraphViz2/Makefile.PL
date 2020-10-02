#!/usr/bin/env perl

use strict;
use warnings;

use Config;

use ExtUtils::MakeMaker;

use File::Spec;
use File::Temp;

require 5.010001; # For the utf8 stuff.

# -----------------------------------------------

sub is_dot_installed
{
  # 1: Create a temp file containing DOT commands.
  # The EXLOCK option is for BSD-based systems.
  # newdir() croaks() if it fails, which is what we want.
  # Hence there is no need to use Try::Tiny.

  my($temp_dir) = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
  my($gv_file)  = File::Spec -> catfile($temp_dir, 'test.gv');

  # We use the deprecated 2-argument form of open in case
  # this code is run on an ancient version of Perl.

  open(OUT, ">$gv_file")                   || die "Can't create temp file: $!\n";
  print OUT "digraph graph_14 {node_14}\n" || die "Can't write to temp file: $!\n";
  close OUT                                || die "Can't close temp file: $!\n";

  # 2: Run dot to create an SVG file.

  my $stdout = `dot -Tsvg $gv_file`;

  # 3: If that failed, we die.

  die "Please install Graphviz from http://www.graphviz.org/\n" if ($stdout !~ m|</svg>|);

} # End of is_dot_installed.

# -----------------------------------------------

is_dot_installed();

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
  AUTHOR => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => "A wrapper for AT&T's Graphviz",
  MIN_PERL_VERSION => 5.010001,
  NAME => 'GraphViz2',
  PREREQ_PM => {
    'Data::Section::Simple' => 0.02,
    'File::Which' => 1.21,
    'IPC::Run3' => 0.048,
    'Log::Handler' => 0.84,
    'Moo' => 2.001001,
    'Set::Array' => 0.23,
    'Types::Standard' => 1.000005,
    'Try::Tiny' => 0.09,
  },
  TEST_REQUIRES => {
    'Test::More' => 1.001002,
    'charnames' => 0,
    'open' => 0,
  },
  VERSION_FROM => 'lib/GraphViz2.pm',
  LICENSE => 'perl',
  META_MERGE => {
    'meta-spec' => {
      version => 2,
    },
    dynamic_config => 0,
    resources => {
      bugtracker => { web => 'https://github.com/ronsavage/GraphViz2/issues' },
      license => 'http://dev.perl.org/licenses/',
      repository => {
        type => 'git',
        url => 'https://github.com/ronsavage/GraphViz2.git',
        web => 'https://github.com/ronsavage/GraphViz2',
      },
    },
    prereqs => {
      develop => {
        requires => {
          'Test::Pod' => '1.48',
          'Pod::Markdown' => 0,
        },
        suggests => {
          # for generating the website stuff
          'Text::Xslate' => 1.2000,
          'HTTP::Tiny' => 0.012,
          'HTML::TreeBuilder' => 4.2,
          'Date::Simple' => 3.03,
          'Config::Tiny' => 2.16,
          'File::HomeDir' => 0.99,
        },
      },
    },
  },
);

WriteMakefile(%params);

sub MY::postamble {
  return '' if !-e '.git';
  <<EOF;
pure_all :: README.md

README.md : \$(VERSION_FROM)
\tpod2markdown \$< >\$\@
EOF
}

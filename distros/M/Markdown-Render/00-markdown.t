#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{$Bin/..};
use FindBin qw($Bin);

use Data::Dumper;
use English qw{-no_match_vars};
use Test::More;

our %TESTS = (
    new             => 'Markdown::Render->new',
    render_markdown => 'render HTML from markdown file',
);

########################################################################

plan tests => 1 + keys %TESTS;

# Find the test input file.
my $test_file;
for ('files', '..') {
    my $file = "$Bin/$_/README.md.in";
    if (-f $file) {
        $test_file = $file;
        last;
    }
}

BAIL_OUT("Unable to find test file")
    unless defined $test_file;

use_ok('Markdown::Render');

########################################################################
subtest 'new' => sub {
########################################################################
  my $md = eval {
    Markdown::Render->new(
      infile => $test_file,
      engine => 'text_markdown',
    );
  };

  ok( !$EVAL_ERROR, 'new' )
    or do {
    diag( Dumper( [$EVAL_ERROR] ) );
    BAIL_OUT('could not instantiate Markdown::Render');
    };
};

########################################################################
subtest 'render_markdown' => sub {
########################################################################
  my $md = eval {
    Markdown::Render->new(
      infile => $test_file,
      engine => 'text_markdown',
    );
  };

  ok( !$EVAL_ERROR, 'new(infile => file)' )
    or do {
    diag( Dumper( [$EVAL_ERROR] ) );
    BAIL_OUT('could not instantiate Markdown::Render');
    };

  ok( $md->get_markdown, 'read markdown file' );
  ok( !$md->get_html,    'no html yet' );

  isa_ok( $md->render_markdown, 'Markdown::Render' );

  ok( $md->get_html, 'render HTML' );

  ok( $md->render_markdown->get_html, 'retrieve HTML' );

  ok( $md->finalize_markdown->render_markdown->get_html,
    'finalize and render' );
};

1;

__DATA__
END_OF_PLAN

#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;

use English;
use File::Basename 'basename', 'dirname';
use File::Find 'find';
use File::Spec::Functions 'abs2rel';
use FindBin;

our $VERSION = 0.02;

BEGIN {
  if (not $ENV{EXTENDED_TESTING}) {
    skip_all('Extended test. Set $ENV{EXTENDED_TESTING} to a true value to run.');
  }
}

BEGIN {
  eval 'use IPC::Run3';  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
  if ($EVAL_ERROR) {
    my $msg = 'IPC::Run3 required to spell check code';
    skip_all($msg);
  }
}

my $aspell = `which aspell 2> /dev/null`;  ## no critic (ProhibitBacktickOperators)

my $root = $FindBin::Bin.'/..';

my $mode = (@ARGV && $ARGV[0] eq '--interactive') ? 'interactive' : 'list';

my @base_cmd =
    ('aspell', '--encoding=utf-8', "--home-dir=${root}", '--lang=en', '-p', '.aspelldict');

# For some reasons, the --mode=perl option of Aspell does not work correctly (in
# all cases, it would not handle POD content). so we are passing manually the
# options to the "context" filters underlying the perl mode.
my %lang_filter = (
  markdown => ['--mode=markdown'],
  perl => [
    '--mode=none', '--add-filter=url',
    '--add-filter=context', '--clear-context-delimiters',
    '--add-context-delimiters==pod =cut', '--add-context-delimiters=# \0',
    '--add-context-delimiters=" "', "--add-context-delimiters=' '"
  ]
);

if (not $aspell) {
  skip_all('The aspell program is required in the path to check the spelling.');
}

sub list_bad_words {
  my ($file, $type) = @_;
  my $bad_words;
  my @cmd = (@base_cmd, @{$lang_filter{$type}}, 'list');
  run3(\@cmd, $file, \$bad_words) or die "Can’t run aspell: $!\n";
  return $bad_words;
}

sub interactive_check {
  my ($file, $type) = @_;
  my @cmd = (@base_cmd, @{$lang_filter{$type}}, 'check', $file);
  return system @cmd;
}

# Note: while strings in Perl modules are checked, the POD content is ignored
# unfortunately.

sub wanted {
  # We should do something more generic to not recurse in Git sub-modules.
  $File::Find::prune = 1 if -d && m/^ (?: blib | third_party | \..+ ) $/x;
  return unless -f;

  my $type;
  if (m/\.(?:pm|pod)$/ || basename($File::Find::dir) eq 'script') {
    $type = 'perl';
  } elsif (m/\.md$/) {
    $type = 'markdown';
  } else {
    return;
  }

  my $file_from_root = abs2rel($File::Find::name, $root);
  if ($mode eq 'list') {
    like(list_bad_words($_, $type), qr/^\s*$/, "Spell-checking ${file_from_root} (${type})");
  } elsif ($mode eq 'interactive') {
    is(interactive_check($_, $type),
      0, "Interactive spell-checking for ${file_from_root} (${type})");
  } else {
    die "Unknown operating mode: '${mode}'";
  }

  return;
}

find(\&wanted, $root);
done_testing();

#!/usr/bin/perl

# Test that every email read has the right prologue.

use strict;

use File::Temp qw(tempfile);
use Test::More;
use lib 't';
use Mail::Mbox::MessageParser;
use Mail::Mbox::MessageParser::Config;
use File::Spec::Functions qw(:ALL);
use Test::Utils;
use FileHandle;

eval 'require Storable;';

my @files = <t/mailboxes/*.txt>;

plan (tests => 3 * scalar (@files));

foreach my $filename (@files) 
{
  print "Testing filename: $filename\n";

  TestImplementation($filename,0,0);

  SKIP:
  {
    skip('Storable not installed',1) unless defined $Storable::VERSION;

    InitializeCache($filename);

    TestImplementation($filename,1,0);
  }

  SKIP:
  {
    skip('GNU grep not available',1)
      unless defined $Mail::Mbox::MessageParser::Config{'programs'}{'grep'};

    TestImplementation($filename,0,1);
  }
}

# ---------------------------------------------------------------------------

sub TestImplementation
{
  my $filename = shift;
  my $enable_cache = shift;
  my $enable_grep = shift;

  my $testname = [splitdir($0)]->[-1];
  $testname =~ s/\.t//;

  my ($folder_name) = $filename =~ /\/([^\/]*)\.txt$/;

  my ($output_fh, $output_fn) = tempfile();
  binmode $output_fh;

  my $filehandle = new FileHandle($filename);

  my ($cache_fh, $cache_fn) = tempfile();

  Mail::Mbox::MessageParser::SETUP_CACHE({'file_name' => $cache_fn})
    if $enable_cache;

  my $folder_reader =
      new Mail::Mbox::MessageParser( {
        'file_name' => $filename,
        'file_handle' => $filehandle,
        'enable_cache' => $enable_cache,
        'enable_grep' => $enable_grep,
        'debug' => $ENV{TEST_VERBOSE},
      } );

  die $folder_reader unless ref $folder_reader;

  my $prologue = $folder_reader->prologue;
  ok(0),return if $folder_name eq 'newlines_at_beginning' && $prologue ne "\n";
  ok(0),return if $folder_name ne 'newlines_at_beginning' && $prologue ne "";
  print $output_fh $prologue;

  # This is the main loop. It's executed once for each email
  while(!$folder_reader->end_of_file())
  {
    my $email_text = $folder_reader->read_next_email();

    print $output_fh $$email_text;
  }

  $output_fh->close();

  CheckDiffs([$filename,$output_fn]);
}

# ---------------------------------------------------------------------------


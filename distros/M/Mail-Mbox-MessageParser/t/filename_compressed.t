#!/usr/bin/perl

# Test that the module will correctly open a compressed filename

use strict;

use File::Temp qw(tempfile);
use Test::More;
use lib 't';
use Mail::Mbox::MessageParser;
use Mail::Mbox::MessageParser::Config;
use Mail::Mbox::MessageParser::Cache;
use Mail::Mbox::MessageParser::Grep;
use Mail::Mbox::MessageParser::Perl;
use File::Spec::Functions qw(:ALL);
use Test::Utils;
use FileHandle;

my @files = <t/mailboxes/*.txt.*>;
@files = grep { !/non-mailbox/ && !/malformed/ } @files;

plan (tests => 1 * scalar (@files));

foreach my $filename (@files) 
{
  print "Testing filename: $filename\n";

  SKIP:
  {
    skip('bzip2 not available',1)
      if $filename =~ /\.bz2$/ &&
        !defined $Mail::Mbox::MessageParser::Config{'programs'}{'bzip2'};
    skip('bzip not available',1)
      if $filename =~ /\.bz$/ &&
        !defined $Mail::Mbox::MessageParser::Config{'programs'}{'bzip'};
    skip('lzip not available',1)
      if $filename =~ /\.lz$/ &&
        !defined $Mail::Mbox::MessageParser::Config{'programs'}{'lzip'};
    skip('xz not available',1)
      if $filename =~ /\.xz$/ &&
        !defined $Mail::Mbox::MessageParser::Config{'programs'}{'xz'};
    skip('gzip not available',1)
      if $filename =~ /\.gz$/ &&
        !defined $Mail::Mbox::MessageParser::Config{'programs'}{'gzip'};

    TestImplementation($filename,0,0);
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

  my ($folder_name) = $filename =~ /\/([^\/\\]*)\.txt.*$/;

  my ($output_fh, $output_fn) = tempfile();
  binmode $output_fh;

  my $filehandle = new FileHandle($filename);

  my ($cache_fh, $cache_fn) = tempfile();

  Mail::Mbox::MessageParser::SETUP_CACHE({'file_name' => $cache_fn})
    if $enable_cache;

  my $folder_reader =
      new Mail::Mbox::MessageParser( {
        'file_name' => $filename,
        'file_handle' => undef,
        'enable_cache' => $enable_cache,
        'enable_grep' => $enable_grep,
        'debug' => $ENV{TEST_VERBOSE},
      } );

  die $folder_reader unless ref $folder_reader;

  my $prologue = $folder_reader->prologue;
  print $output_fh $prologue;

  # This is the main loop. It's executed once for each email
  while(!$folder_reader->end_of_file())
  {
    my $email_text = $folder_reader->read_next_email();

    print $output_fh $$email_text;
  }

  $output_fh->close();

  $filename =~ s#\.(tz|bz2|lz|xz|gz)$##;

  CheckDiffs([$filename,$output_fn]);
}

# ---------------------------------------------------------------------------

#!/usr/bin/perl

# Test that every email read has the right starting index number.

use strict;

use File::Temp;
use Test::More;
use lib 't';
use Mail::Mbox::MessageParser;
use Mail::Mbox::MessageParser::Config;
use File::Spec::Functions qw(:ALL);
use Test::Utils;
use FileHandle;

eval 'require Storable;';

my @files = <t/mailboxes/*.txt>;
@files = grep { $_ ne 't/mailboxes/vm-emacs.txt' } @files;

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

  my $output = File::Temp->new();
  binmode $output;

  my $filehandle = new FileHandle($filename);

  my $cache = File::Temp->new();

  Mail::Mbox::MessageParser::SETUP_CACHE({'file_name' => $cache->filename})
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

  # This is the main loop. It's executed once for each email
  while(!$folder_reader->end_of_file())
  {
    $folder_reader->read_next_email();

    print $output $folder_reader->number() . "\n";
  }

  $output->close();

  my $compare_filename = 
    catfile('t','results',"${testname}_${folder_name}.stdout");

  CheckDiffs([$compare_filename,$output->filename]);
}

# ---------------------------------------------------------------------------


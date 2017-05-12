#!/usr/bin/perl

# Test that we can process file handles for compressed and non-compressed
# files.

use strict;

use File::Temp;
use Test::More;
use lib 't';
use Mail::Mbox::MessageParser;
use Mail::Mbox::MessageParser::Config;
use Test::Utils;
use FileHandle;

eval 'require Storable;';

my @files = <t/mailboxes/mailarc-1*.txt>;

plan (tests => 4 * scalar (@files));

foreach my $filename (@files) 
{
  print "Testing filename: $filename\n";

  TestImplementation($filename,0,0);

  SKIP:
  {
    skip('Storable not installed',2) unless defined $Storable::VERSION;

    InitializeCache($filename);

    TestImplementation($filename,1,0);
    TestImplementation($filename,1,1);
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

  my $cache = File::Temp->new();

  Mail::Mbox::MessageParser::SETUP_CACHE({'file_name' => $cache->filename})
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

  if ($filename =~ /-dos/)
  {
    is($folder_reader->endline(),"\r\n",'Dos endline expected');
  }
  else
  {
    is($folder_reader->endline(),"\n",'Unix endline expected');
  }
}

# ---------------------------------------------------------------------------


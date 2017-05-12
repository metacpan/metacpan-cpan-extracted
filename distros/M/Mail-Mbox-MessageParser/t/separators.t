#!/usr/bin/perl

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

my %tests = (
  "t/mailboxes/separators1.sep" => 4,
  "t/mailboxes/separators2.sep" => 2,
);

plan (tests => 3 * scalar (keys %tests));

foreach my $filename (keys %tests) 
{
  print "Testing filename: $filename\n";

  SKIP:
  {
    skip('Storable not installed',2) unless defined $Storable::VERSION;

    InitializeCache($filename);

    TestImplementation($filename,$tests{$filename},1,0);
    TestImplementation($filename,$tests{$filename},1,1);
  }

  SKIP:
  {
    skip('GNU grep not available',1)
      unless defined $Mail::Mbox::MessageParser::Config{'programs'}{'grep'};

    TestImplementation($filename,$tests{$filename},0,1);
  }
}

# ---------------------------------------------------------------------------

sub TestImplementation
{
  my $filename = shift;
  my $number_of_emails = shift;
  my $enable_cache = shift;
  my $enable_grep = shift;

  my $testname = [splitdir($0)]->[-1];
  $testname =~ s/\.t//;

  my ($folder_name) = $filename =~ /\/([^\/\\]*)\..*?$/;

  my $output = File::Temp->new();
  binmode $output;

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

  my $prologue = $folder_reader->prologue;
  print $output $prologue;

  my $count = 0;

  # This is the main loop. It's executed once for each email
  while(!$folder_reader->end_of_file())
  {
    my $email_text = $folder_reader->read_next_email();

    $count++;
  }

  $output->close();

  is($count,$number_of_emails, "Number of emails in $filename");
}

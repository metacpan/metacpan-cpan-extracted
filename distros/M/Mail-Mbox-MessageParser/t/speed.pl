#!/usr/bin/perl

# These tests operate on a mail archive I found on the web at
# http://el.www.media.mit.edu/groups/el/projects/handy-board/mailarc.txt
# and then broke into pieces

use strict;
use warnings 'all';
use Config;
use File::Slurper qw(read_text);

use lib 't';
use Test::Utils;
use Benchmark;

my $MAILBOX_SIZE = 10_000_000;
my $TEMP_MAILBOX = "$TEMPDIR/bigmailbox.txt";

my $path_to_perl = $Config{perlpath};

my @IMPLEMENTATIONS_TO_TEST = (
'Perl',
'Grep',
'Cache Init',
'Cache Use',
);

my @mailboxes = CreateInputFiles($TEMP_MAILBOX);

pop @mailboxes;

foreach my $mailbox (@mailboxes)
{
  print "\n";

  {
    local $" = ", ";
    print "Executing speed tests for @IMPLEMENTATIONS_TO_TEST on \"$mailbox\"\n\n";
  }

  my $data = CollectData($mailbox);

  print "=========================================\n";

  DoHeadToHeadComparison($data);

  print "=========================================\n";

  DoImplementationsComparison($data);

  print "#########################################\n";
}

# make clean will take care of it
#END
#{
#  RemoveInputFile($TEMP_MAILBOX);
#}

################################################################################

sub RemoveInputFile
{
  my $filename = shift;

  unlink $filename;
}

################################################################################

sub CreateInputFiles
{
  my $filename = shift;

  my @mailboxes;

  unless(-e $filename && abs((-s $filename) - $MAILBOX_SIZE) <= $MAILBOX_SIZE*.1)
  {
    print "Making input file ($MAILBOX_SIZE bytes).\n";

    my $data = read_text('t/mailboxes/mailarc-1.txt', undef, 1);

    open FILE, ">$filename";

    my $number = 0;

    while (-s $filename < $MAILBOX_SIZE)
    {
      print FILE $data, "\n";

      $number++;

      # Also make an email with a 1MB attachment.
      print FILE<<"EOF";
From XXXXXXXX\@XXXXXXX.XXX.XXX.XXX Sat Apr 19 19:30:45 2003
Received: from XXXXXX.XXX.XXX.XXX (XXXXXX.XXX.XXX.XXX [##.##.#.##]) by XXX.XXXXXXXX.XXX id h3JNTvkA009295 envelope-from XXXXXXXX\@XXXXXXX.XXX.XXX.XXX for <XXXXX XXXXXX.XXX>; Sat, 19 Apr 2003 19:29:57 -0400 (EDT)8f/81N9n7q
        (envelope-from XXXXXXXX\@XXXXXXX.XXX.XXX.XXX)
Date: Sat, 19 Apr 2003 19:29:50 -0400 (EDT)
From: Xxxxxxx Xxxxxxxx <xxxxxxxx\@xxxxxx.xxx.xxx.xxx>
To: "'Xxxxx Xxxxxx'" <xxxxx\@xxxxxx.xxx>
Subject: RE: FW: Xxxxxx--xxxxxx xxxxxxxx xxxxx xxxxxxx (xxx)
Message-ID: <Pine.LNX.4.44.0304191837520.30945-$number\@xxxxxxx.xxx.xxx.xxx>
MIME-Version: 1.0
Content-Type: MULTIPART/MIXED; BOUNDARY="873612032-418625252-1050794990=:31078"

  This message is in MIME format.  The first part should be readable text,
  while the remaining parts are likely unreadable without MIME-aware tools.
  Send mail to mime\@docserver.cac.washington.edu for more info.

--873612032-418625252-1050794990=:31078
Content-Type: TEXT/PLAIN; charset=US-ASCII

I am not sure if the message below went through.  I accidentally
attached too big a file with it.  Now it's nicely zipped.

--873612032-418625252-1050794990=:31078
Content-Type: APPLICATION/x-gzip; name="testera_dft_4_mchaff.tar.gz"
Content-Transfer-Encoding: BASE64
Content-ID: <Pine.LNX.4.44.0304191929500.3$number\@xxxxxxx.xxx.xxx.xxx>
Content-Description:
Content-Disposition: attachment; filename="foo.tar.gz"

EOF

      print FILE (('x' x 74 . "\n" ) x (1_000_000 / 74));

      print FILE "--873612032-418625252-1050794990=:31078--\n\n";
    }

    close FILE;
  }

  unlink "$filename.gz" if -e "$filename.gz";

  print "Making compressed input file.\n";

  system "gzip -c --force --best $filename > $filename.gz";

  return ($filename, "$filename.gz");
}

################################################################################

my $test_program;

sub CollectData
{
  my $filename = shift;

  print "Collecting data...\n\n";

  $test_program = read_file(\*DATA) unless defined $test_program;

  # I couldn't get the module to reload right, so we'll create an external program
  # to do the testing
  {
    local $" = "', '";
    my $implementations_to_test = "'@IMPLEMENTATIONS_TO_TEST'";
    $test_program =~ s/\@IMPLEMENTATIONS_TO_TEST/$implementations_to_test/g;
  }

  $test_program =~ s/\$TEMPDIR/$TEMPDIR/g;

  write_file("$TEMPDIR/test_speed.pl", $test_program);

  my %data;

  foreach my $old_or_new (qw(New Old))
  {
    my $results = `$path_to_perl $TEMPDIR/test_speed.pl $old_or_new`;

    die $results unless $results =~ /VAR1/;

    my $VAR1;
    eval $results;

    %data = (%data, %$VAR1);
  } 

  return \%data;
}

################################################################################

sub DoHeadToHeadComparison
{
  my $data = shift;

  print "HEAD TO HEAD COMPARISON\n\n";

  my @labels = grep { s/New // } keys %$data;

  my $first = 1;

  foreach my $label (@labels)
  {
    next unless exists $data->{"Old $label"} && exists $data->{"New $label"};

    print "-----------------------------------------\n"
      unless $first;

    my %head_to_head = ("Old $label" => $data->{"Old $label"},
      "New $label" => $data->{"New $label"});
    Benchmark::cmpthese(\%head_to_head);

    $first = 0;
  }
}

################################################################################

sub DoImplementationsComparison
{
  my $data = shift;

  print "IMPLEMENTATION COMPARISON\n\n";

  {
    my @old_labels = grep { /Old / } keys %$data;

    my %old;
    
    foreach my $label (@old_labels)
    {
      $old{$label} = $data->{$label};
    }

    Benchmark::cmpthese(\%old);
  }

  print "-----------------------------------------\n";

  {
    my @new_labels = grep { /New / } keys %$data;

    my %new;
    
    foreach my $label (@new_labels)
    {
      $new{$label} = $data->{$label};
    }

    Benchmark::cmpthese(\%new);
  }
}

################################################################################

__DATA__

use strict;
use lib 'lib';
use Benchmark;
use Benchmark::Timer;
use FileHandle;

die unless @ARGV == 1;

my $old_or_new = $ARGV[0];
my $modpath = $old_or_new eq 'New' ? 'lib' : 'old';

my $filename = "$TEMPDIR/bigmailbox.txt";

my %data;

unshift @INC, $modpath;
require Mail::Mbox::MessageParser;

my %settings =
(
  'Perl' => [0,0],
  'Grep' => [0,1],
  'Cache Init' => [1,1],
  'Cache Use' => [1,0],
);

foreach my $file_type ('Filename', 'Filehandle')
{
  # Take this out soon
  next if $old_or_new eq 'Old' && $file_type eq 'Filename';

  foreach my $impl (@IMPLEMENTATIONS_TO_TEST)
  {
    my $label = "$old_or_new $impl $file_type";

    my $t = new Benchmark::Timer(skip => 2, minimum => 5, confidence => 98.5, error => 2);
    $| = 1;

    # Need enough for the statistics to be valid
    while ($t->need_more_samples($label))
    {
      unlink "$TEMPDIR/cache" if $impl eq 'Cache Init';

      if ($impl eq 'Cache Init')
      {
        $t->start($label);
        InitializeCache($filename, $file_type);
        $t->stop($label);
      }
      else
      {
        $t->start($label);
        ParseFile($filename,$settings{$impl}[0],$settings{$impl}[1], $file_type);
        $t->stop($label);
      }
    }

    $t->report($label);

    # Fake a benchmark object so we can compare later using Benchmark
    $data{$label} = new Benchmark;
    $data{$label}[5] = 1;
    $data{$label}[1] = $t->result($label);
    $data{$label}[2] = 0;
  }
}

use Data::Dumper;
print Dumper \%data;

exit;

################################################################################

sub InitializeCache
{
  my $filename = shift;
  my $file_type = shift;

  Mail::Mbox::MessageParser::SETUP_CACHE({'file_name' => "$TEMPDIR/cache"});
  Mail::Mbox::MessageParser::MetaInfo::CLEAR_CACHE();

  my $filehandle;
  $filehandle = new FileHandle($filename) if $file_type eq 'Filehandle';

  my $folder_reader =
      new Mail::Mbox::MessageParser( {
        'file_name' => $filename,
        'file_handle' => $filehandle,
        'enable_cache' => 1,
        'enable_grep' => 0,
      } );

  my $prologue = $folder_reader->prologue;

  # This is the main loop. It's executed once for each email
  while(!$folder_reader->end_of_file())
  {
    $folder_reader->read_next_email();
  }

  Mail::Mbox::MessageParser::MetaInfo::WRITE_CACHE();
}

################################################################################

sub ParseFile
{
  my $filename = shift;
  my $enable_cache = shift;
  my $enable_grep = shift;
  my $file_type = shift;

  my $file_handle;
  $file_handle = new FileHandle($filename) if $file_type eq 'Filehandle';

  Mail::Mbox::MessageParser::SETUP_CACHE({'file_name' => "$TEMPDIR/cache"})
    if $enable_cache;

  my $folder_reader =
      new Mail::Mbox::MessageParser( {
        'file_name' => $filename,
        'file_handle' => $file_handle,
        'enable_cache' => $enable_cache,
        'enable_grep' => $enable_grep,
      } );

  while (!$folder_reader->end_of_file())
  {
    my $email_text = $folder_reader->read_next_email();
  }

  close $file_handle if $file_type eq 'Filehandle';
}

################################################################################

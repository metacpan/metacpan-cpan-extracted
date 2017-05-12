#!/usr/bin/perl -w

use strict;
use MP3::Tag;

my ($mp3, $count, $v1, $v2)=(undef,0,0,0);

die "usage: tagged.pl filename(s)" if $#ARGV == -1;

my $t = time;

for my $filename (@ARGV) {
  next until -f $filename;
  print " --  $filename:\n";

  $mp3 = MP3::Tag->new($filename);
  $mp3->get_tags;
  $count++;
  if (exists $mp3->{ID3v1}) {
    $v1++;
    print " ** found ID3v1 - TAG\n";
    print "   Song: " .$mp3->{ID3v1}->song . "\n";
    print " Artist: " .$mp3->{ID3v1}->artist . "\n";
    print "  Album: " .$mp3->{ID3v1}->album . "\n";
    print "Comment: " .$mp3->{ID3v1}->comment . "\n";
    print "   Year: " .$mp3->{ID3v1}->year . "\n";
    print "  Genre: " .$mp3->{ID3v1}->genre . "\n";
    print "  Track: " .$mp3->{ID3v1}->track . "\n";
    if (0==1) { # write a test tag
      $mp3->new_tag("ID3v1") unless exists $mp3->{ID3v1};
      $mp3->{ID3v1}->comment("This is only a Test Tag");
      $mp3->{ID3v1}->song("testing");
      $mp3->{ID3v1}->genre("Blues");
      $mp3->{ID3v1}->artist("Artest");
      $mp3->{ID3v1}->album("Test it");
      $mp3->{ID3v1}->year("1965");    
      $mp3->{ID3v1}->track("5");
      # or at once
      # $mp3->{ID3v1}->all("song title","artist","album","1900","comment",10,"Ska");
      $mp3->{ID3v1}->write_tag;
    }
  }
  if (exists $mp3->{ID3v2}) {
    $v2++;
    print " **  found ID3v2 - TAG; size = $mp3->{ID3v2}->{tagsize} (+10);\n";
    my $frames = $mp3->{ID3v2}->get_frame_ids();
    foreach my $frame (keys %$frames) {
       my ($info, $name) = $mp3->{ID3v2}->get_frame($frame);
       next unless defined $info;
       if (ref $info) {
	print "$frame $name:\n";
	while(my ($key,$val)=each %$info) {
	  if (0==1 && $frame eq "APIC" && $key eq "_Data") { # view pics
	    open (FH, ">/tmp/temp.$v2");
	    print FH $val;
	    close FH;
	    system("xview /tmp/temp.$v2 &"); #choose this to another program if you want
	  }
	  $val= length($val) ." Bytes" if $key =~ /^_/; # _... means binary data
	  $val =~ s/\0/\\0/g;		# Multiple strings in a frame
	  print "  *  $key => '$val'\n" unless $key eq "tagname";
	}
      } else {
	$info =~ s/\0/', '/g;		# Multiple strings in a frame
	print "$frame $name: '$info'\n";
      }
    }
    if (0==1) { # add a id3v2 comment
      $mp3->new_tag("ID3v2") unless exists $mp3->{ID3v2};
      $mp3->{ID3v2}->add_frame("COMM","ENG","Test","This is an example, how to add an ID3v2 frame");
      $mp3->{ID3v2}->write_tag;
    }
  }
}

warn "$count Files | $v1 ID3v1 Tags | $v2 ID3v2 Tags | ". (time-$t) . "s \n"; 

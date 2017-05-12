#!/usr/local/bin/perl

BEGIN { $| = 1; }
use Image::Grab;
use diagnostics;

# You need cookies for www.chron.com for this to work.
# See http://www.chron.com/content/comics

# Net connection?
if(!-f "t/have_network") {
  print "1..0\n";
  exit 0;
}

if(-f "$ENV{HOME}/.netscape/cookies") {
  open(COOKIE, "$ENV{HOME}/.netscape/cookies");
  unless (grep {/www.chron.com/} <COOKIE>) {
    print "1..0\n";
    close(COOKIE);
    exit 0;
  }
  close(COOKIE);
} else {
  print "1..0\n";
  exit 0;
}

my $toons = [
# These require cookies
{Name => "One Big Happy",
 url => "http://www.chron.com/content/chronicle/comics/One_Big_Happy.g.gif",
 "link" => "http://www.chron.com/content/comics",
 },
{Name => "9 Chickweed Lane",
 url => "http://www.chron.com/content/chronicle/comics/9_Chickweed_Lane.g.gif",
 "link" => "http://www.chron.com/content/comics",
 },
{Name => "Liberty Meadows",
 url => "http://www.chron.com/content/chronicle/comics/Liberty_Meadows.g.gif",
 "link" => "http://www.chron.com/content/comics",
}];

print "1..", $#{$toons} + 1,"\n";
my $num=0;
my $name;
foreach (@$toons)  {
  $num++;
  $name = $_->{Name};
  print "$name\n";
  $comic->{$name} = new Image::Grab;
  $comic->{$name}->url($_->{url}) if defined $_->{url};
  $comic->{$name}->refer($_->{refer}) if defined $_->{refer};
  $comic->{$name}->regexp($_->{regexp}) if defined $_->{regexp};

  print "\turl:    ", $_->{url}, "\n" if defined $_->{url};
  print "\trefer:  ", $_->{refer}, "\n" if defined $_->{refer};
  print "\tregexp: ", $_->{regexp}, "\n" if defined $_->{regexp};
  print "\treal:   ", $comic->{$name}->expand_url, "\n";
# getAllURLs should really be fixed so that it only has to fetch once.
  print "\t\t", join("\n\t\t", $comic->{$name}->getAllURLs), "\n" if $_->{refer};

  print "ok $num\n";
}

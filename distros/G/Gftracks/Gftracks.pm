#!/usr/bin/perl
package Gftracks;
use warnings;
use strict;
use Data::Dumper;
use Exporter;
our @ISA=qw / Exporter /;
our @EXPORT = qw / instime init deltrack printtracks shell/;
# Normally sec should only be used internally, but just in case, 
# we make it possible to pull it in.
our @EXPORT_OK = qw /sec tidytime /;
our $VERSION="0.9";
# Returns number of secounds calculated from a grf timestamp

sub sec{
  my ($h,$m,$s)=split(':',$_[0]);
  $s+=$m*60;
  $s+=$h*3600;
  return $s;
}

=head1 NAME

Gftracks - Perl extention for manipulation of gramofiles .tracks files


=head1 SYNOPSIS

Usually the interactive shell will be used. The variable TRACKS shall point to
the .tracks file to be edited

   export TRACKS=/home/myhome/myrecord.wav.tracks

   perl -MGftracks -e shell;


Within the shell, press h for help.

=head1 DESCRIPTION

The .tracks file is read into an array, where the 0th element holds the 
metadata for the file, and each of the other elements holds the information 
for the actual track.


=head1 SUBROUTINES

For all the subroutines the variable $tracks indicates an array build up in the
module. 

Those subroutines with a name starting with _ are not exported.


=head2 instime(timestamp)

instime inserts a track at a given timestamp

 ins(\@tracks,$timestamp[,$duration]);
 If duration is not defined, the end of the track is set to the
 current end of the track in which the insertion is performed

=cut

sub instime{
  my @tracks=@{$_[0]};
  my $timestamp=$_[1];
  my $duration=$_[2] || undef; 
  return \@tracks if $duration; # $duration still does not work
  my $timesec=sec($timestamp);
  foreach (1..$#tracks){
    # Search until either, we find the track which the new is to be inserted 
    # into, or we are on the last track. (To avoid warning, the checks are done
    # the other way around
    next unless ($_ == $#tracks or(
		 sec($tracks[$_]{start})< $timesec) 
		 and (sec($tracks[$_+1]{start})> $timesec));
    if (sec($tracks[$_]{end})>$timesec){ # Unless the insert is between two tracks
      my $new={start=>$timestamp,
	       end=>$tracks[$_]{end}};
      splice(@tracks,$_+1,0,$new);    
      $tracks[$_]{end}=$timestamp;
    }else{
      if ($duration){
	my $new={start=>$timestamp,
		 end=>$tracks[$_+1]{end}};
	splice(@tracks,$_+1,0,$new);    
	$tracks[$_]{end}=$timestamp;
      }
    }
    last;
  }
  $tracks[0]{Number_of_tracks}=$#tracks;
  return \@tracks;
}

=head2 _spliceback and _splicefwd

 _spliceback and _splicefwd splices the rest of the array when
 a track has been deleted. They should only be used internally. 
 In both cases the arguments are a pointer to the tracks array and 
 the index that is to be deleted

=cut

# _spliceback removes a track by combining it with the previous track
sub _spliceback{
  my $tracks=shift;
  my $delno =shift;
  $tracks->[$delno-1]{end}=$tracks->[$delno]{end};
  splice (@$tracks,$delno,1);
  return $tracks;
}

# _spliceback removes a track by combining it with the next track
sub _splicefwd{
  my $tracks=shift;
  my $delno =shift;
  $tracks->[$delno+1]{start}=$tracks->[$delno]{start};
  splice (@$tracks,$delno,1);
  return $tracks;
}

=head2 deltrack

 deltrack (\@tracks,$index,$back)

Deltrack removes a track by default using spliceback (unless the last track 
is deleted).

=cut

sub deltrack{
  my $tracks=shift;
  my $delno =shift;
  my $back = $delno == $#{$tracks} || shift;
  # $tracks->[0] must not be deleted, as it holds the meta info
  return $tracks unless $delno*1; 
  return $tracks if $delno >$#{$tracks};
  $tracks = $back ?  _spliceback($tracks,$delno) : _splicefwd($tracks,$delno);
  $tracks->[0]{Number_of_tracks}=$#{$tracks};
  return $tracks;
}

=head2 trackfile

trackfile returns the filename as given by $ENV{TRACKS} and does some simple
sanity checking on it

=cut

sub _trackfile{
# Could add a function that returns a *.track file if that
# is the only one found in the active directory  
  my $file= $ENV{TRACKS};
  warn("Is $file a .tracks file?") unless $file=~/.tracks$/;
  return $file;

}

=head2 init

init($filename) reads the file as specified by filename and returns the array
holding all the information in the .tracks-file

=cut 

sub init{
  my (@lines,@tracks,$nooftracks, $comment, %data,$tracks);
  my $file=$_[0] || _trackfile;
  my $savefile=$file.".bak";
  print "$file\n" if $ENV{GRFDEBUG};
  open (FILE,"<$file") || die ("Cannot open $file");
  open (BACKUP,">$savefile") || warn ("Cannot create backupfile, $savefile\n");
  my $i;
  while(<FILE>){
    print BACKUP $_;
    if (!$nooftracks && /Number_of_tracks.(\d+)/)
      {
	$nooftracks=$1;
      }
    chomp;
    push @lines , $_;
    $tracks=$tracks || /Track ?\d/;
    unless($tracks){
      next if /^#/;
      my($key,$var)=split(/=/,$_);
      $data{$key}=$var if $var;
      next;
    }
    $comment=$_ if /^#/;
    if (/^Track(\d+)(start|end)=(.*)$/) {
      $tracks[$1]{$2}=$3;
      # The last comment is the one connected to the current track
      $tracks[$1]{comment}=$comment; 
      # If the {end} element is not defined for current track, then
      # we are at start and calculates the start timestamp
      $tracks[$1]{starttime}=sec($3) unless ($tracks[$1]{end});
    }
  }
  $tracks[0]=\%data;
  return \@tracks;
}

=head2 tidytime

$timestamp=tidytime(timestamp)

Does some sanitychecking of the time stamp and tidies up a bit so that the 
returned timestamp is on the form hh:mm:ss.sss

=cut

sub tidytime{
  my $zerotime="0:00:00.000";
  my $timestamp=shift;
  $timestamp.=' ';
  $timestamp=~m/(\d\D)?(\d{2})\D(\d{2}(\.\d{1,3})?)?/;
#  print "<$1|$2|$3|$4>\n";
  my $sec= ($3 || '0');
  $sec.='.' unless $4;
  $sec='0'.$sec if $sec < 10;
  $sec.='0'x(6-length($sec));
  my $hour= ($1 || '0 ');
  chop($hour);
  return "$hour:$2:$sec";

}

=head2 Shellcommands

=head3 shellhelp

Prints out some basic help for the shell commands

=cut


sub shellhelp{
  print <<ENDHELP
    h         : help
    a <t>     : add a track at given time
    d <n>     : delete the given track
    n         : print number of tracks
    p         : print start and end times for all tracks
    b <n> <t> : alter beginning of track
    e <n> <t> : alter end of track
    s         : save file
    q         : quit
    ---------------------------------------------------------
    <t> time,  must be given as h:mm:ss.ss 
    <n> tracknumber
    (c) Morten Sickel (cpan\@sickel.net) April 2005
    The last version should be available at http://sickel.net
    Licenced under the artistic licence

ENDHELP
}

=head3 shelladjusttime

shelladjusttime ($tracks,$command,$end)

adjusts the time for start or end of a track. End is either set to 'start' or 
'end'.

=cut

sub shelladjusttime{
  # adjusts the time for start or end of a track
  my $tracks=shift;
  my $command=shift;
  my $end=shift;
  $command=~/\w+\s+(\d+)\s+(.*)/;
  my $time=tidytime($2);
  $$tracks[$1]{$end}=$time;
}

=head3 shelladd

shelladd($tracks,$timestamp)
Adds  track at a given time

=cut


sub shelladd{

  my $tracks  = shift;
  my $timestamp = shift;
  $timestamp=~m/^\w+\s+(.*)/;
  $timestamp=$1;
  $tracks=instime($tracks,$timestamp);
  
}

=head3 shelldelete

shelldelete($tracks,$trackno)

uses deltrack() to delete the indicated track

=cut


sub shelldelete{
  my ($tracks,$trackno)=@_;
  $trackno=~m/^\w+\s+(.*)/;
  $trackno=$1;
  $tracks=deltrack($tracks,$trackno);
}

=head3 shellprint
shellprint($tracks)
prints out the number of tracks

=cut

sub shellprint{
  my $tracks = shift;
  print $#$tracks," tracks\n";
}

=head3 shellsave

shellsave($tracks,$filename)
saves the information to $filename

=cut

sub shellsave{
  my($tracks,$file)=@_;
  open OUT,">$file";
  print OUT printtracks($tracks);
  close OUT;
}

=head3 shellprinttracks

shellprinttracks($tracks)

prints out the beginning and end time of all the tracks

=cut

sub shellprinttracks{
  my $tracks=shift;
  my @tracks=@$tracks;
  my $i;
  print "track from"." "x10,"to\n";
  print "-"x(6+4+10+11),"\n";
  foreach $i (1..$#tracks){
    print "  $i"," "x(4-length($i)),$tracks[$i]->{start},
      " - ",$tracks[$i]->{end},"\n";
  }
  

}

=head2 shell

shell($file)

shell will fetch the filename from _trackfile if not given.

shell opens up a quite simple interactive shell for editing. 

The following commands are valid:

    h         : help
    a <t>     : add a track at given time
    d <n>     : delete the given track
    n         : print number of tracks
    p         : print start and end times for all tracks
    b <n> <t> : alter beginning of track
    e <n> <t> : alter end of track
    s         : save file
    q         : quit
    ---------------------------------------------------------
    <t> time,  must be given as h:mm:ss.ss 
    <n> tracknumber


=cut


sub shell{
  my $file = shift || _trackfile;
  $file=~tr/ //d;
  die("Use the environment variable TRACKS to set tracks file\n")
    unless $file;
  my $tracks=init($file);
  die('Cannot find tracks file, use the environment variable TRACKS')
    unless $tracks;
  print "press 'h' for help\n";
  while(1){
    print " > ";
    my $command = <>;
    last if $command=~/^q/i;
    shellhelp if $command =~/^h/i;
    $tracks=shelladd($tracks,$command) if $command =~/^a/;
    shellprint($tracks) if $command=~/^n/;
    $tracks=shelldelete($tracks,$command) if $command=~/^d/;
    shellsave($tracks,$file) if $command=~/^s/;
    shellprinttracks($tracks) if $command=~/^p/;
    shelladjusttime($tracks,$command,'start') if $command=~/^b/;
    shelladjusttime($tracks,$command,'end') if $command=~/^e/;
  }
}

=head2 printtracks

printtracks($tracks)

returns the information in $tracks. Suitable for saving.

=cut

sub printtracks{
  my $tracks=shift;
  my @tracks=@$tracks;
  my $not="Number_of_tracks";
  my $buffer="[Tracks]";
  foreach (keys %{$tracks[0]}){
    $buffer .= "$_=$$tracks[0]{$_}\n" if $_ ne $not;
  }
  $buffer.= "\n".$not."=".$$tracks[0]{$not}."\n\n";
  my $i;
  foreach $i (1..$#tracks){
    $i="0".$i if $i<10;
    no warnings;

    $buffer.= $tracks[$i]->{comment}."\n";
    $buffer.= "Track${i}start=".$tracks[$i]->{start}."\n";
    $buffer.= "Track${i}end=".$tracks[$i]->{end}."\n\n";
    use warnings;
  }
  return $buffer;
}

1;


=head1 LICENCE

    (c) Morten Sickel (cpan\@sickel.net) April 2005
    The last version should be available at http://sickel.net
    Licenced under the artistic licence

=cut

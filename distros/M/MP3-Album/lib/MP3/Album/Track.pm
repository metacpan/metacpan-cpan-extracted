package MP3::Album::Track;

use strict;
use MP3::Info qw(:all);
use Data::Dumper;
use File::Copy;

sub new {
   my $c = shift;
   my %a = @_;
   my $b = {};

   unless ($a{filename}) {
	$@ = "missing parameter filename";
	return undef;
   }

   my $s = bless $b, $c;

   $s->{info} = MP3::Info->new("$a{filename}");

   unless ($s->{info}) {
	$@ = "$a{filename} does not apear to be a valid mp3";
	return undef;
   }

   $s->{filename} = $a{filename};

   return $s;
}

sub filename { my $s = shift; return $s->{filename} }

sub bitrate {
   my $s = shift;
   return $s->{info}->{BITRATE};
}

sub frequency {
   my $s = shift;
   return $s->{info}->{FREQUENCY};
}

sub set_tag {
   my $s = shift;
   my %a = @_;

   $a{title}  |= '';
   $a{artist} |= '';
   $a{album}  |= '';
   $a{year}   |= '';
   $a{comment}|= '';
   $a{genre}  |= '';

   my $rs;
   eval {
     $rs = set_mp3tag($s->{filename}, $a{title}, $a{artist}, $a{album}, $a{year}, $a{comment}, $a{genre}, $a{track_number});
   };

   $s->{info} = MP3::Info->new($s->{filename});

   return $rs;
}

sub rename {
   my $s = shift;
   my %a = @_;

   $a{keep_copy} |= 0;

   unless ($a{filename}) {
	$@ = "missing param filename";
	return undef;
   }

   my $r;
   if ( $a{keep_copy} ) {
	$r = copy($s->{filename}, $a{filename});
   } else {
	$r = move($s->{filename}, $a{filename});
   }

   if (!$r) { $@ = "$!"; return undef}

   $s->{filename} = $a{filename};

   return 1;
}

1;

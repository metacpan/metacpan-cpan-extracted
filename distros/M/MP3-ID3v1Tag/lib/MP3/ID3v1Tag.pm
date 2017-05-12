package MP3::ID3v1Tag;
require 5.004;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# $Id: ID3v1Tag.pm,v 2.11 2000/09/01 00:26:18 sander Exp $
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use IO::File;

require Exporter;
@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

$MP3::ID3v1Tag::VERSION = do { my @r = (q$Revision: 2.11 $ =~ /\d+/g); $r[0]--;sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

## Revision and debuging
$MP3::ID3v1Tag::revision = '$Id: ID3v1Tag.pm,v 2.11 2000/09/01 00:26:18 sander Exp $ ';
my $DEBUG = 0;

## SOME USEFULL CONSTANTS.
## see http://www.dv.co.yu/mpgscript/mpeghdr.htm
##     by Predrag Supurovic <mpgtools@dv.co.yu>
##     http://www.id3.org/
my $DefaultClass = 'MP3::ID3v1Tag';

@MP3::ID3v1Tag::id3_genres_array = (
			'Blues', 'Classic Rock', 'Country', 'Dance',
			'Disco', 'Funk', 'Grunge', 'Hip-Hop', 'Jazz',
			'Metal', 'New Age', 'Oldies', 'Other', 'Pop', 'R&B',
			'Rap', 'Reggae', 'Rock', 'Techno', 'Industrial',
			'Alternative', 'Ska', 'Death Metal', 'Pranks',
			'Soundtrack', 'Euro-Techno', 'Ambient', 'Trip-Hop',
			'Vocal', 'Jazz+Funk', 'Fusion', 'Trance',
			'Classical', 'Instrumental', 'Acid', 'House',
			'Game', 'Sound Clip', 'Gospel', 'Noise',
			'AlternRock', 'Bass', 'Soul', 'Punk', 'Space',
			'Meditative', 'Instrumental Pop',
			'Instrumental Rock', 'Ethnic', 'Gothic', 'Darkwave',
			'Techno-Industrial', 'Electronic', 'Pop-Folk',
			'Eurodance', 'Dream', 'Southern Rock', 'Comedy',
			'Cult', 'Gangsta', 'Top 40', 'Christian Rap',
			'Pop/Funk', 'Jungle', 'Native American', 'Cabaret',
			'New Wave', 'Psychadelic', 'Rave', 'Showtunes',
			'Trailer', 'Lo-Fi', 'Tribal', 'Acid Punk',
			'Acid Jazz', 'Polka', 'Retro', 'Musical',
			'Rock & Roll',
			'Hard Rock', 'Folk', 'Folk/Rock', 'National Folk',
			'Swing', 'Fast Fusion', 'Bebob', 'Latin', 'Revival',
			'Celtic', 'Bluegrass', 'Avantgarde', 'Gothic Rock',
			'Progressive Rock', 'Psychedelic Rock',
			'Symphonic Rock', 'Slow Rock', 'Big Band',
			'Chorus', 'Easy Listening', 'Acoustic', 'Humour',
			'Speech',
			'Chanson', 'Opera', 'Chamber Music', 'Sonata',
			'Symphony', 'Booty Bass', 'Primus', 'Porn Groove',
			'Satire', 'Slow Jam', 'Club', 'Tango', 'Samba',
			'Folklore', 'Ballad', 'Power Ballad',
			'Rhythmic Soul', 'Freestyle', 'Duet',
			'Punk Rock', 'Drum Solo', 'Acapella',
			'Euro-house', 'Dance Hall'
		       );

my $c = 0;
%MP3::ID3v1Tag::id3_genres = map {$_ => $c++ } @MP3::ID3v1Tag::id3_genres_array;

## A silly print routine useful for debugging.
sub debug {
  my($self,$message) = @_;
  print STDERR "$message\n" if $DEBUG;
}

## Constructor for Object of Module
sub new {
  my($class,$mp3_file,$readonly) = @_;
  my $self = {};
  $readonly = 0 unless defined($readonly);
  $self->{FileHandle} = new IO::File;
  if( -w $mp3_file || !$readonly)  {
    $self->{FileHandle}->open("+<${mp3_file}") or (warn("Can't open ${mp3_file}: $!") and return undef);
    $self->{readonly} = 0;
  } else {
    $self->{FileHandle}->open("<${mp3_file}") or (warn("Can't open ${mp3_file}: $!") and return undef);
    $self->{readonly} = 1;
  }
  $self->{filename} = $mp3_file;
  $self->{tag} = ();
  bless($self, ref $class || $class || $DefaultClass);
  my $initialized = $self->init();
  return $self;
}

# We provide a DESTROY method so that the autoloader
# doesn't bother trying to find it.
sub DESTROY {
  my($self) = @_;
  $self->{FileHandle}->close();
}

## Generic routine to see if this MP3 has an ID3v1Tag
sub got_tag {
  my($self) = @_;
  return ($self->find_tag_id3v1())?1:0;
}

## Some generic initialization
## Find the headers and be ready for questions.
sub init {
  my($self) = @_;
  my $bytestring ="";
  $bytestring = $self->find_tag_id3v1();
  if(!defined($bytestring)) {
    return 0;
  } else {
    $self->decode_tag_id3v1($bytestring);
  }
  return 1;
}

## Print a Genre Chart for easy reference.
sub print_genre_chart {
  my($self,$columns) = @_;
  $columns = 3 if ($columns <=0);
  my $i = 0;
  for(my $i = 0;$i < $#MP3::ID3v1Tag::id3_genres_array+1 ; $i += $columns) {
    for(my $j = 0;($j < $columns) && ($i + $j < $#MP3::ID3v1Tag::id3_genres_array+1); $j++) {
      printf("%2s. %-20s",$i + $j, $MP3::ID3v1Tag::id3_genres_array[$i + $j]);
    }
    print "\n";
  }
}

## ID3v1 TAG at the END of the File.
## Talks about ID3v2 being at the beginning of the file.
sub find_tag_id3v1 {
  my($self) = @_;
  my($bytes,$line);
  ## MusicMatch has their data here aswell, but they are planning
  ## on supporting ID3 to prevent issues.
  $self->{FileHandle}->seek(-128,SEEK_END); # Find the last 128 bytes
  while($line = $self->{FileHandle}->getline()) { $bytes .= $line; }
  return undef if $bytes !~ /^TAG/; # Must have Tag Ident to be valid.
  return $bytes;
}


## Decode the ID3v1 Tag into useful tidbits.
sub decode_tag_id3v1 {
  my($self,$buffer) = @_;
  ## Unpack the Audio ID3v1
  (undef, @{$self->{tag}}{qw/title artist album year comment genre_num/}) =
    unpack('a3a30a30a30a4a30C1', $buffer);
  
  ## Clean em up a bit
  foreach (sort keys %{$self->{tag}}) {
    if(defined($self->{tag}{$_})) {
      $self->{tag}{$_} =~ s/\s+$//;
      $self->{tag}{$_} =~ s/\0.*$//;
      $self->debug(sprintf("ID3v1: %s = ", $_ ) . $self->{tag}{$_});
    }
  }
  $self->{tag}{'genre'} = $MP3::ID3v1Tag::id3_genres_array[$self->{tag}{'genre_num'}];
  $self->debug(sprintf("ID3v1: %s = ", 'genre' ) . $self->{tag}{'genre'});
}

sub encode_tag_id3v1 {
  my($self) = @_;
  ## Visit the beginning of the id3 tag if it exists
  return 0 if($self->{readonly});
  if(!defined($self->find_tag_id3v1())) {
    $self->debug("Going to Append Tag");
    # No Tag
    $self->{FileHandle}->seek(0,SEEK_END); # Find EOF
  } else {
    $self->debug("Going to Re-write Tag.");
    $self->{FileHandle}->seek(-128,SEEK_END); # Find the last 128 bytes
  }
  $self->{tag}{'genre_num'} = 255 if(!defined($self->{tag}{'genre_num'}));
  $self->{FileHandle}->print(pack("a3a30a30a30a4a30C1", 
			  'TAG',
			  $self->{tag}{'title'},
			  $self->{tag}{'artist'},
			  $self->{tag}{'album'},
			  $self->{tag}{'year'},
			  $self->{tag}{'comment'},
			  $self->{tag}{'genre_num'}));
  $self->{FileHandle}->flush();
  return 1;
}

sub remove_tag {
  my($self) = @_;
  return 0 if($self->{readonly});
  return 1 if(!defined($self->find_tag_id3v1()));
  my $filesize = (stat($self->{FileHandle}))[7];
  $self->debug("Removing Tag: File size = $filesize");
  my $success = truncate($self->{FileHandle},($filesize - 128));
  $filesize = (stat($self->{FileHandle}))[7];
  $self->debug("Removed Tag : File size = $filesize");
}

sub save {
  my($self) = @_;
  return $self->encode_tag_id3v1();
}
## Print the Tag to default File Handler (usually STDOUT)
sub print_tag {
  my($self) = @_;

  if(defined($self->{tag})) {
    foreach (sort keys %{$self->{tag}}) {
      print(sprintf("%-10s = ",$_ ) . $self->{tag}{$_} . "\n");
    }
  } else {
    print "No ID3v1 Tag Found\n";
  }
}


##
sub get_title {
  my($self) = @_;
  return $self->{tag}{'title'};
}
sub set_title {
  my ($self,$title) = @_;
  $self->{tag}{'title'} = $title;
}

##
sub get_artist {
  my($self) = @_;
  return $self->{tag}{'artist'};
}
sub set_artist {
  my($self,$artist) = @_;
  $self->{tag}{'artist'} = $artist;
}

##
sub get_album {
  my($self) = @_;
  return $self->{tag}{'album'};
}
sub set_album {
  my($self,$album) = @_;
  $self->{tag}{'album'} = $album;
}

##
sub get_year {
  my($self) = @_;
  return $self->{tag}{'year'};
}
sub set_year {
  my($self,$year) = @_;
  $self->{tag}{'year'} = $year;
}

sub get_comment {
  my($self) = @_;
  return $self->{tag}{'comment'};
}
sub set_comment {
  my($self,$comment) = @_;
  $self->{tag}{'comment'} = $comment;
}

sub set_genre {
  my($self,$genre) = @_;
  my $genre_num = $MP3::ID3v1Tag::id3_genres{$genre};
  if($genre_num >= 0 && $genre_num <= $#MP3::ID3v1Tag::id3_genres_array) {
    $self->{tag}{'genre'} = $genre;
    $self->{tag}{'genre_num'} = $genre_num;
  }
}

sub get_genre {
  my($self) = @_;
  return $self->{tag}{'genre'};
}

sub set_genre_num {
  my($self,$genre_num) = @_;
  if( $genre_num >= 0 && $genre_num <= $#MP3::ID3v1Tag::id3_genres_array) {
    $self->{tag}{'genre_num'} = $genre_num;
    $self->{tag}{'genre'} = $MP3::ID3v1Tag::id3_genres_array[$genre_num];
    return 1;
  }
  return 0;
}
  
sub get_genre_num {
  my($self) = @_;
  return $self->{tag}{'genre_num'};
}
  
## Gives direct access to the %tag hash
sub tag {
  my($self,$key) = @_;
  return wantarray ? keys %{$self->{tag}}: $self->{tag}{$key};
}

  
1;

=pod

=head1 NAME

MP3::ID3v1Tag - Edit ID3v1 Tags from an Audio MPEG Layer 3.

=head1 SYNOPSIS

  use MP3::ID3v1Tag;

  $mp3_file = new MP3::ID3v1Tag("filename.mp3");
  $mp3_file->print_tag();

  if($mp3_file->got_tag()) {
     $mp3_file->set_title($title); 
     $save_status = $mp3_file->save();
  }


=head1 DESCRIPTION

The ID3v1Tag routines are useful for setting and reading ID3 MP3 Audio Tags.
Just create an MP3::ID3v1Tag Object with the path to the file of interest,
and query any of the methods below.

=head2 Print Full ID3 Tag 

To get a print out of all the header information (Default FileHandler), simply
state the following

$mp3_file->print_tag();

=head2 Print Genre Chart

With an optional number of columns argument (default is 3) this will
return a list of genre numbers with their appropriate genre.

$mp3_file->print_genre_chart($COLUMNS);

=head2 Checking for the Existance of ID3 Tags

There is a handy method named got_tag() that can be easily used to determine
if a particular MP3 file contains an ID3 Tag.

  if $mp3_file->got_tag() {
     $mp3_file->print_tag();
  }

=head2 Viewing Tag Compontents individually

There exist several methods that will return you the individual components
of the ID3 Tag.

  $title     = $mp3_file->get_title();
  $artist    = $mp3_file->get_artist();
  $album     = $mp3_file->get_album();
  $year      = $mp3_file->get_year();
  $genre     = $mp3_file->get_genre();
  $genre_num = $mp3_file->get_genre_num();
  $comment   = $mp3_file->get_comment();

=head2 Editing and Removing Tags

Similar methods exist to allow you to change the components of the Tag,
but none of the changes will actually be changed in the file until you
call the save() routine.

  $mp3_file->set_title("New Title");
  $mp3_file->set_artist("New Artist");
  $mp3_file->set_album("New Album");
  $mp3_file->set_year(1999);
  $mp3_file->set_genre("Blues"); 
  # Or use the genre numbers ->
  $mp3_file->set_genre_num(0);

To remove an tag in its entirely just calling the remove_tag() method
should work for you.

 $mp3_file->remove_tag() if $mp3_file->got_tag();

 You could access all the components directly for a read only loop such
as the following

foreach (sort $mp3_file->tag) {
    print "$_: " . $mp3_file->tag($_) . "\n";
}


=head1 AUTHOR

Sander van Zoest E<lt>svanzoest@cpan.orgE<gt>

=head1 THANKS

Matt Plummer E<lt>matt@mp3.comE<gt>, Mike Oliphant E<lt>oliphant@gtk.orgE<gt>, 
Matt DiMeo E<lt>mattd@mp3.comE<gt>, Olaf Maetzner, Jason Bodnar and Peter
Johansson

=head1 COPYRIGHT

Copyright 2000, Alexander van Zoest. All rights reserved.
Copyright 1999-2000, Alexander van Zoest, MP3.com, Inc. All rights reserved. 

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=head1 REFERENCES

For general overview of MPEG 1.0, Layer 3 (MP3) Audio visit 
<http://help.mp3.com/help/gettingstarted/guide.html> or get the book,
"MP3: The Definitive Guide" by O'Reilly and Associates
<http://www.oreilly.com/catalog/mp3/>.

For technical details about MP3 Audio read the 
ISO/IEC 11172 and ISO/IEC 13818 specifications, obtained via 
<http://www.ANSI.org/> in the US or <http://www.ISO.ch/> 
elsewhere in the world. For more information also check 
out <http://www.mp3-tech.org/> compiled by Gabriel Bouvigne.

For more specific references to the MP3 Audio ID3 Tags visit 
<http://www.id3.org/>

For information about ID3v2 and a perl implementation see MPEG::ID3v2Tag 
written by Matt DiMeo E<lt>mattd@mp3.comE<gt>.

=cut

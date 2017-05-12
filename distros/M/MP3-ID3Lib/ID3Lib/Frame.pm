package MP3::ID3Lib::Frame;

use strict;
use vars qw($VERSION);

$VERSION = '0.10';

my $FRAMES = [
  { code => "????", description => "No known frame" }, 
  { code => "AENC", description => "Audio encryption" }, 
  { code => "APIC", description => "Attached picture" }, 
  { code => "ASPI", description => "Audio seek point index" }, 
  { code => "COMM", description => "Comments" }, 
  { code => "COMR", description => "Commercial frame" }, 
  { code => "ENCR", description => "Encryption method registration" }, 
  { code => "EQU2", description => "Equalisation (2)" }, 
  { code => "EQUA", description => "Equalization" }, 
  { code => "ETCO", description => "Event timing codes" }, 
  { code => "GEOB", description => "General encapsulated object" }, 
  { code => "GRID", description => "Group identification registration" }, 
  { code => "IPLS", description => "Involved people list" }, 
  { code => "LINK", description => "Linked information" }, 
  { code => "MCDI", description => "Music CD identifier" }, 
  { code => "MLLT", description => "MPEG location lookup table" }, 
  { code => "OWNE", description => "Ownership frame" }, 
  { code => "PRIV", description => "Private frame" }, 
  { code => "PCNT", description => "Play counter" }, 
  { code => "POPM", description => "Popularimeter" }, 
  { code => "POSS", description => "Position synchronisation frame" }, 
  { code => "RBUF", description => "Recommended buffer size" }, 
  { code => "RVA2", description => "Relative volume adjustment (2)" }, 
  { code => "RVAD", description => "Relative volume adjustment" }, 
  { code => "RVRB", description => "Reverb" }, 
  { code => "SEEK", description => "Seek frame" }, 
  { code => "SIGN", description => "Signature frame" }, 
  { code => "SYLT", description => "Synchronized lyric/text" }, 
  { code => "SYTC", description => "Synchronized tempo codes" }, 
  { code => "TALB", description => "Album/Movie/Show title" }, 
  { code => "TBPM", description => "BPM (beats per minute)" }, 
  { code => "TCOM", description => "Composer" }, 
  { code => "TCON", description => "Content type" }, 
  { code => "TCOP", description => "Copyright message" }, 
  { code => "TDAT", description => "Date" }, 
  { code => "TDEN", description => "Encoding time" }, 
  { code => "TDLY", description => "Playlist delay" }, 
  { code => "TDOR", description => "Original release time" }, 
  { code => "TDRC", description => "Recording time" }, 
  { code => "TDRL", description => "Release time" }, 
  { code => "TDTG", description => "Tagging time" }, 
  { code => "TIPL", description => "Involved people list" }, 
  { code => "TENC", description => "Encoded by" }, 
  { code => "TEXT", description => "Lyricist/Text writer" }, 
  { code => "TFLT", description => "File type" }, 
  { code => "TIME", description => "Time" }, 
  { code => "TIT1", description => "Content group description" }, 
  { code => "TIT2", description => "Title/songname/content description" }, 
  { code => "TIT3", description => "Subtitle/Description refinement" }, 
  { code => "TKEY", description => "Initial key" }, 
  { code => "TLAN", description => "Language(s)" }, 
  { code => "TLEN", description => "Length" }, 
  { code => "TMCL", description => "Musician credits list" }, 
  { code => "TMED", description => "Media type" }, 
  { code => "TMOO", description => "Mood" }, 
  { code => "TOAL", description => "Original album/movie/show title" }, 
  { code => "TOFN", description => "Original filename" }, 
  { code => "TOLY", description => "Original lyricist(s)/text writer(s)" }, 
  { code => "TOPE", description => "Original artist(s)/performer(s)" }, 
  { code => "TORY", description => "Original release year" }, 
  { code => "TOWN", description => "File owner/licensee" }, 
  { code => "TPE1", description => "Lead performer(s)/Soloist(s)" }, 
  { code => "TPE2", description => "Band/orchestra/accompaniment" }, 
  { code => "TPE3", description => "Conductor/performer refinement" }, 
  { code => "TPE4", description => "Interpreted, remixed, or otherwise modified by" }, 
  { code => "TPOS", description => "Part of a set" }, 
  { code => "TPRO", description => "Produced notice" }, 
  { code => "TPUB", description => "Publisher" }, 
  { code => "TRCK", description => "Track number/Position in set" }, 
  { code => "TRDA", description => "Recording dates" }, 
  { code => "TRSN", description => "Internet radio station name" }, 
  { code => "TRSO", description => "Internet radio station owner" }, 
  { code => "TSIZ", description => "Size" }, 
  { code => "TSOA", description => "Album sort order" }, 
  { code => "TSOP", description => "Performer sort order" }, 
  { code => "TSOT", description => "Title sort order" }, 
  { code => "TSRC", description => "ISRC (international standard recording code)" }, 
  { code => "TSSE", description => "Software/Hardware and settings used for encoding" }, 
  { code => "TSST", description => "Set subtitle" }, 
  { code => "TXXX", description => "User defined text information" }, 
  { code => "TYER", description => "Year" }, 
  { code => "UFID", description => "Unique file identifier" }, 
  { code => "USER", description => "Terms of use" }, 
  { code => "USLT", description => "Unsynchronized lyric/text transcription" }, 
  { code => "WCOM", description => "Commercial information" }, 
  { code => "WCOP", description => "Copyright/Legal infromation" }, 
  { code => "WOAF", description => "Official audio file webpage" }, 
  { code => "WOAR", description => "Official artist/performer webpage" }, 
  { code => "WOAS", description => "Official audio source webpage" }, 
  { code => "WORS", description => "Official internet radio station homepage" }, 
  { code => "WPAY", description => "Payment" }, 
  { code => "WPUB", description => "Official publisher webpage" }, 
  { code => "WXXX", description => "User defined URL link" }, 
  { code => "    ", description => "Encrypted meta frame (id3v2.2.x)" }, 
  { code => "    ", description => "Compressed meta frame (id3v2.2.1)" }, 
  { code => ">>>>", description => "Last field placeholder" }, 
];

sub new {
  my($class, $conf) = @_;

  my $self = {};
  if ($conf->{type}) {
    my $type = $conf->{type};
    $self->{type} = $type;
    $self->{code} = $FRAMES->[$type]->{code};
    $self->{description} = $FRAMES->[$type]->{description};
  }

  $self->{index} = $conf->{index};
  $self->{value} = $conf->{value};
  $self->{is_changed} = 0;

  bless $self, $class;
  return $self;
}

sub value {
  my $self = shift;
  return $self->{value};
}

sub get {
  my $self = shift;
  return $self->{value};
}

sub set {
  my($self, $value) = @_;
  $self->{value} = $value;
  $self->{is_changed} = 1;
}

sub code {
  my $self = shift;
  return $self->{code};
}

sub offset {
  my $self = shift;
  return $self->{offset};
}

sub description {
  my $self = shift;
  return $self->{description};
}

sub is_new {
  my $self = shift;
  return $self->{is_new};
}

sub is_changed {
  my $self = shift;
  return $self->{is_changed};
}

1;

__END__

=head1 NAME

MP3::ID3Lib::Frame - ID3v1/ID3v2 Tagging Frames

=head1 SYNOPSIS

  use MP3::ID3Lib;
  my $id3 = MP3::ID3Lib->new($filename);

  foreach my $frame (@{$id3->frames}) {
    my $code = $frame->code;
    my $description = $frame->description;
    my $value = $frame->value;
    $frame->set("Orange") if $code eq 'COMM';
    print "$description: $value\n";
  }
  $id3->commit;

=head1 DESCRIPTION

See MP3::ID3Lib for more information.

=head1 AUTHOR

Leon Brocard, leon@astray.com

=head1 COPYRIGHT

Copyright (c) 2002 Leon Brocard. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

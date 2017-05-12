package MP3::ID3Lib;

use strict;
use vars qw($VERSION @ISA);
use MP3::ID3Lib::Frame;

require DynaLoader;
require AutoLoader;

@ISA = qw(DynaLoader);
$VERSION = '0.12';

bootstrap MP3::ID3Lib $VERSION;

my $IDS = {
  '????' => 0, 
  'AENC' => 1, 
  'APIC' => 2, 
  'ASPI' => 3, 
  'COMM' => 4, 
  'COMR' => 5, 
  'ENCR' => 6, 
  'EQU2' => 7, 
  'EQUA' => 8, 
  'ETCO' => 9, 
  'GEOB' => 10, 
  'GRID' => 11, 
  'IPLS' => 12, 
  'LINK' => 13, 
  'MCDI' => 14, 
  'MLLT' => 15, 
  'OWNE' => 16, 
  'PRIV' => 17, 
  'PCNT' => 18, 
  'POPM' => 19, 
  'POSS' => 20, 
  'RBUF' => 21, 
  'RVA2' => 22, 
  'RVAD' => 23, 
  'RVRB' => 24, 
  'SEEK' => 25, 
  'SIGN' => 26, 
  'SYLT' => 27, 
  'SYTC' => 28, 
  'TALB' => 29, 
  'TBPM' => 30, 
  'TCOM' => 31, 
  'TCON' => 32, 
  'TCOP' => 33, 
  'TDAT' => 34, 
  'TDEN' => 35, 
  'TDLY' => 36, 
  'TDOR' => 37, 
  'TDRC' => 38, 
  'TDRL' => 39, 
  'TDTG' => 40, 
  'TIPL' => 41, 
  'TENC' => 42, 
  'TEXT' => 43, 
  'TFLT' => 44, 
  'TIME' => 45, 
  'TIT1' => 46, 
  'TIT2' => 47, 
  'TIT3' => 48, 
  'TKEY' => 49, 
  'TLAN' => 50, 
  'TLEN' => 51, 
  'TMCL' => 52, 
  'TMED' => 53, 
  'TMOO' => 54, 
  'TOAL' => 55, 
  'TOFN' => 56, 
  'TOLY' => 57, 
  'TOPE' => 58, 
  'TORY' => 59, 
  'TOWN' => 60, 
  'TPE1' => 61, 
  'TPE2' => 62, 
  'TPE3' => 63, 
  'TPE4' => 64, 
  'TPOS' => 65, 
  'TPRO' => 66, 
  'TPUB' => 67, 
  'TRCK' => 68, 
  'TRDA' => 69, 
  'TRSN' => 70, 
  'TRSO' => 71, 
  'TSIZ' => 72, 
  'TSOA' => 73, 
  'TSOP' => 74, 
  'TSOT' => 75, 
  'TSRC' => 76, 
  'TSSE' => 77, 
  'TSST' => 78, 
  'TXXX' => 79, 
  'TYER' => 80, 
  'UFID' => 81, 
  'USER' => 82, 
  'USLT' => 83, 
  'WCOM' => 84, 
  'WCOP' => 85, 
  'WOAF' => 86, 
  'WOAR' => 87, 
  'WOAS' => 88, 
  'WORS' => 89, 
  'WPAY' => 90, 
  'WPUB' => 91, 
  'WXXX' => 92, 
  '    ' => 93, 
  '    ' => 94, 
  '>>>>' => 95, 
};

sub new {
  my $class = shift;
  my $filename = shift;

  my $self = {};
  my $id3 = MP3::ID3LibXS->create($filename);
  $self->{id3} = $id3;

  my @frames;
  foreach my $f (@{$id3->frames}) {
    my $frame = MP3::ID3Lib::Frame->new({
      type => $f->{type},
      index => $f->{index},
      value => $f->{value},
    });
    push @frames, $frame;
  }
  $self->{frames} = \@frames;

  bless $self, $class;
  return $self;
}

sub frames {
  my $self = shift;
  return $self->{frames};
}

sub add_frame {
  my($self, $code, $value) = @_;
  my $id3 = $self->{id3};
  my $id = $IDS->{$code};
  die "code $code is invalid" unless $id;
  $id3->add_frame($id, $value);
}

sub commit {
  my $self = shift;
  my $id3 = $self->{id3};
  my $frames = $self->{frames};
  $id3->commit($frames);
}

1;
__END__

=head1 NAME

MP3::ID3Lib - ID3v1/ID3v2 Tagging of MP3 files

=head1 SYNOPSIS

  use MP3::ID3Lib;
  my $id3 = MP3::ID3Lib->new($filename);

  foreach my $frame (@{$id3->frames}) {
    my $code = $frame->code;
    my $description = $frame->description;
    my $value = $frame->value;
    $frame->set("Orange") if $code eq 'TPE1';
    print "$description: $value\n";
  }

  $id3->add_frame("TIT2", "Title goes here");
  $id3->commit;

=head1 DESCRIPTION

This module allows you to edit and add ID3 tags in MP3 files. 

ID3 tags are small pieces of information stored inside the MP3
file. They can contain bits of metadata about the MP3, such as album
name, song name, artist, original artist, genre, composer, year of
release, additional comment fields, and many more.

This module is an interface to the high-quality id3lib library
available from http://id3lib.sourceforge.net/, which must be installed.
At the moment, it is a bit of a low-level interface and some knowledge
of ID3v2 is useful. You should know about tag names and tag
usage. The best website for this is http://www.id3.org/.

However, to get started, a few frame names you may find useful are:

=over 4

=item * TIT2: Title/songname/content description

=item * TPE1: Lead performer(s)/Soloist(s) (artist)

=item * TALB: Album/Movie/Show title

=item * TRCK: Track number/Position in set

=item * TYER: Year

=item * TCON: Content type ('genre')

=item * COMM: Comments

=back

Please note that id3v1 has length restrictions on these fields.

=head1 BUGS

The API could be better and there are a couple of small memory leaks.

This module currently only returns the first 100 ASCII characters of a
text tag.

This module is currently unable to read or write ID3 v2.4.0 tags.

=head1 THANKS

Thanks go to Chris Nandor for letting me use his test MP3s and to Paul
Mison for the idea.

=head1 AUTHOR

Leon Brocard, leon@astray.com

=head1 COPYRIGHT

Copyright (c) 2002 Leon Brocard. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

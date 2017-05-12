################################################################################
#
#  $Revision: 4 $
#  $Author: mhx $
#  $Date: 2009/10/02 22:35:00 +0200 $
#
################################################################################
# 
# Copyright (c) 2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

package MP4::File;

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION $XS_VERSION);
use XSLoader;
use Exporter;

@ISA = qw( Exporter );

$VERSION = do { my @r = '$Snapshot: /MP4-File/0.08 $' =~ /(\d+\.\d+(?:_\d+)?)/; @r ? $r[0] : '9.99' };
$XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

XSLoader::load 'MP4::File', $XS_VERSION;

%EXPORT_TAGS = (
  constants => [qw(
    MP4_OD_TRACK_TYPE
    MP4_SCENE_TRACK_TYPE
    MP4_AUDIO_TRACK_TYPE
    MP4_VIDEO_TRACK_TYPE
    MP4_HINT_TRACK_TYPE
    MP4_CNTL_TRACK_TYPE
    MP4_CLOCK_TRACK_TYPE
    MP4_MPEG7_TRACK_TYPE
    MP4_OCI_TRACK_TYPE
    MP4_IPMP_TRACK_TYPE
    MP4_MPEGJ_TRACK_TYPE
  )],
);

@EXPORT_OK = map @$_, values %EXPORT_TAGS;

1;

__END__

=head1 NAME

MP4::File - Read/Write MP4 files

=head1 SYNOPSIS

  use MP4::File;

  $mp4 = MP4::File->new;

  $mp4->Modify($filename);
  $mp4->SetMetadataArtist("Dire Straits");

  $mp4->Close;

  MP4::File->Optimize($filename);

=head1 DESCRIPTION

Please refer to the libmp4v2 documentation for details.

=head2 FileInfo

  $info = MP4::File->FileInfo($fileName, $trackId = 0)

=head2 Optimize

  $ok = MP4::File->Optimize($fileName, $newFileName = 0, $verbosity = 0)

=head2 new

  $mp4 = MP4::File->new()

=head2 Read

  $ok = $mp4->Read($fileName, $verbosity = 0)

=head2 Modify

  $ok = $mp4->Modify($fileName, $verbosity = 0, $flags = 0)

=head2 Info

  $info = $mp4->Info($trackId = 0)

=head2 Close

  $ok = $mp4->Close()

=head2 GetVerbosity

  $verbosity = $mp4->GetVerbosity()

=head2 SetVerbosity

  $ok = $mp4->SetVerbosity($verbosity)

=head2 FindTrackId

  $trackId = $mp4->FindTrackId($index, $type = 0, $subType = 0)

=head2 GetTrackType

  $type = $mp4->GetTrackType($trackId)

$type is one of the following constants that may be imported using:

  use MP4::File qw( :constants );

=head3 MP4_AUDIO_TRACK_TYPE

=head3 MP4_CLOCK_TRACK_TYPE

=head3 MP4_CNTL_TRACK_TYPE

=head3 MP4_HINT_TRACK_TYPE

=head3 MP4_IPMP_TRACK_TYPE

=head3 MP4_MPEG7_TRACK_TYPE

=head3 MP4_MPEGJ_TRACK_TYPE

=head3 MP4_OCI_TRACK_TYPE

=head3 MP4_OD_TRACK_TYPE

=head3 MP4_SCENE_TRACK_TYPE

=head3 MP4_VIDEO_TRACK_TYPE

=head2 GetTrackDuration

  $seconds = $mp4->GetTrackDuration($trackId)

=head2 GetTrackBitRate

  $bps = $mp4->GetTrackBitRate($trackId)

=head2 GetTrackTimeScale

  $scale = $mp4->GetTrackTimeScale($trackId)

=head2 MetadataDelete

  $ok = $mp4->MetadataDelete()

=head2 DeleteMetadataName

  $ok = $mp4->DeleteMetadataName()

=head2 DeleteMetadataArtist

  $ok = $mp4->DeleteMetadataArtist()

=head2 DeleteMetadataWriter

  $ok = $mp4->DeleteMetadataWriter()

=head2 DeleteMetadataComment

  $ok = $mp4->DeleteMetadataComment()

=head2 DeleteMetadataTool

  $ok = $mp4->DeleteMetadataTool()

=head2 DeleteMetadataYear

  $ok = $mp4->DeleteMetadataYear()

=head2 DeleteMetadataAlbum

  $ok = $mp4->DeleteMetadataAlbum()

=head2 DeleteMetadataGenre

  $ok = $mp4->DeleteMetadataGenre()

=head2 DeleteMetadataGrouping

  $ok = $mp4->DeleteMetadataGrouping()

=head2 DeleteMetadataCoverArt

  $ok = $mp4->DeleteMetadataCoverArt()

=head2 DeleteMetadataTrack

  $ok = $mp4->DeleteMetadataTrack()

=head2 DeleteMetadataDisk

  $ok = $mp4->DeleteMetadataDisk()

=head2 DeleteMetadataTempo

  $ok = $mp4->DeleteMetadataTempo()

=head2 DeleteMetadataCompilation

  $ok = $mp4->DeleteMetadataCompilation()

=head2 GetMetadataName

  $string = $mp4->GetMetadataName()

=head2 GetMetadataArtist

  $string = $mp4->GetMetadataArtist()

=head2 GetMetadataWriter

  $string = $mp4->GetMetadataWriter()

=head2 GetMetadataComment

  $string = $mp4->GetMetadataComment()

=head2 GetMetadataTool

  $string = $mp4->GetMetadataTool()

=head2 GetMetadataYear

  $string = $mp4->GetMetadataYear()

=head2 GetMetadataAlbum

  $string = $mp4->GetMetadataAlbum()

=head2 GetMetadataGenre

  $string = $mp4->GetMetadataGenre()

=head2 GetMetadataGrouping

  $string = $mp4->GetMetadataGrouping()

=head2 GetMetadataCoverArtCount

  $number = $mp4->GetMetadataCoverArtCount()

=head2 GetMetadataCoverArt

  $binary = $mp4->GetMetadataCoverArt()

=head2 GetMetadataTrack

  ($curr, $total) = $mp4->GetMetadataTrack()

=head2 GetMetadataDisk

  ($curr, $total) = $mp4->GetMetadataDisk()

=head2 GetMetadataTempo

  $tempo = $mp4->GetMetadataTempo()

=head2 GetMetadataCompilation

  $bool = $mp4->GetMetadataCompilation()

=head2 SetMetadataName

  $ok = $mp4->SetMetadataName($string)

=head2 SetMetadataArtist

  $ok = $mp4->SetMetadataArtist($string)

=head2 SetMetadataWriter

  $ok = $mp4->SetMetadataWriter($string)

=head2 SetMetadataComment

  $ok = $mp4->SetMetadataComment($string)

=head2 SetMetadataTool

  $ok = $mp4->SetMetadataTool($string)

=head2 SetMetadataYear

  $ok = $mp4->SetMetadataYear($string)

=head2 SetMetadataAlbum

  $ok = $mp4->SetMetadataAlbum($string)

=head2 SetMetadataGenre

  $ok = $mp4->SetMetadataGenre($string)

=head2 SetMetadataGrouping

  $ok = $mp4->SetMetadataGrouping($string)

=head2 SetMetadataCoverArt

  $ok = $mp4->SetMetadataCoverArt($binary)

=head2 SetMetadataTrack

  $ok = $mp4->SetMetadataTrack($curr, $total)

=head2 SetMetadataDisk

  $ok = $mp4->SetMetadataDisk($curr, $total)

=head2 SetMetadataTempo

  $ok = $mp4->SetMetadataTempo($tempo)

=head2 SetMetadataCompilation

  $ok = $mp4->SetMetadataCompilation($bool)

=head1 AUTHOR

Marcus Holland-Moritz <mhx@cpan.org>

=cut


# This isn't a real module; it's just a chunk of code from
# Media::LibMTP::API separated out so Build.PL can load it.

package
    Media::LibMTP::API;
# This file is part of Media-LibMTP-API 0.04 (May 31, 2014)

# Copyright 2011 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 30 Nov 2011
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#---------------------------------------------------------------------

our %EXPORT_TAGS = (
  debug => [map { "LIBMTP_DEBUG_$_" } qw(NONE PTP PLST USB DATA ALL)],
  filetypes => [map { "LIBMTP_FILETYPE_$_" }
    qw(FOLDER WAV MP3 WMA OGG AUDIBLE MP4 UNDEF_AUDIO WMV AVI MPEG
       ASF QT UNDEF_VIDEO JPEG JFIF TIFF BMP GIF PICT PNG VCALENDAR1
       VCALENDAR2 VCARD2 VCARD3 WINDOWSIMAGEFORMAT WINEXEC TEXT HTML
       FIRMWARE AAC MEDIACARD FLAC MP2 M4A DOC XML XLS PPT MHT JP2 JPX
       ALBUM PLAYLIST UNKNOWN)],
  properties => [map { "LIBMTP_PROPERTY_$_" }
    qw(StorageID ObjectFormat ProtectionStatus ObjectSize
       AssociationType AssociationDesc ObjectFileName DateCreated
       DateModified Keywords ParentObject AllowedFolderContents
       Hidden SystemObject PersistantUniqueObjectIdentifier SyncID
       PropertyBag Name CreatedBy Artist DateAuthored Description
       URLReference LanguageLocale CopyrightInformation Source
       OriginLocation DateAdded NonConsumable CorruptOrUnplayable
       ProducerSerialNumber RepresentativeSampleFormat
       RepresentativeSampleSize RepresentativeSampleHeight
       RepresentativeSampleWidth RepresentativeSampleDuration
       RepresentativeSampleData Width Height Duration Rating Track
       Genre Credits Lyrics SubscriptionContentID ProducedBy
       UseCount SkipCount LastAccessed ParentalRating MetaGenre
       Composer EffectiveRating Subtitle OriginalReleaseDate
       AlbumName AlbumArtist Mood DRMStatus SubDescription
       IsCropped IsColorCorrected ImageBitDepth Fnumber
       ExposureTime ExposureIndex DisplayName BodyText Subject
       Priority GivenName MiddleNames FamilyName Prefix Suffix
       PhoneticGivenName PhoneticFamilyName EmailPrimary
       EmailPersonal1 EmailPersonal2 EmailBusiness1 EmailBusiness2
       EmailOthers PhoneNumberPrimary PhoneNumberPersonal
       PhoneNumberPersonal2 PhoneNumberBusiness
       PhoneNumberBusiness2 PhoneNumberMobile PhoneNumberMobile2
       FaxNumberPrimary FaxNumberPersonal FaxNumberBusiness
       PagerNumber PhoneNumberOthers PrimaryWebAddress
       PersonalWebAddress BusinessWebAddress
       InstantMessengerAddress InstantMessengerAddress2
       InstantMessengerAddress3 PostalAddressPersonalFull
       PostalAddressPersonalFullLine1
       PostalAddressPersonalFullLine2 PostalAddressPersonalFullCity
       PostalAddressPersonalFullRegion
       PostalAddressPersonalFullPostalCode
       PostalAddressPersonalFullCountry PostalAddressBusinessFull
       PostalAddressBusinessLine1 PostalAddressBusinessLine2
       PostalAddressBusinessCity PostalAddressBusinessRegion
       PostalAddressBusinessPostalCode PostalAddressBusinessCountry
       PostalAddressOtherFull PostalAddressOtherLine1
       PostalAddressOtherLine2 PostalAddressOtherCity
       PostalAddressOtherRegion PostalAddressOtherPostalCode
       PostalAddressOtherCountry OrganizationName
       PhoneticOrganizationName Role Birthdate MessageTo MessageCC
       MessageBCC MessageRead MessageReceivedTime MessageSender
       ActivityBeginTime ActivityEndTime ActivityLocation
       ActivityRequiredAttendees ActivityOptionalAttendees
       ActivityResources ActivityAccepted Owner Editor Webmaster
       URLSource URLDestination TimeBookmark ObjectBookmark
       ByteBookmark LastBuildDate TimetoLive MediaGUID TotalBitRate
       BitRateType SampleRate NumberOfChannels AudioBitDepth
       ScanDepth AudioWAVECodec AudioBitRate VideoFourCCCodec
       VideoBitRate FramesPerThousandSeconds KeyFrameDistance
       BufferSize EncodingQuality EncodingProfile BuyFlag
       UNKNOWN)],
  datatypes => [map { "LIBMTP_DATATYPE_$_" }
    qw(INT8 UINT8 INT16 UINT16 INT32 UINT32 INT64 UINT64)],
  errors => [map { "LIBMTP_ERROR_$_" }
    qw(NONE GENERAL PTP_LAYER USB_LAYER MEMORY_ALLOCATION
       NO_DEVICE_ATTACHED STORAGE_FULL CONNECTING CANCELLED)],
  handler => [map { "LIBMTP_HANDLER_RETURN_$_" } qw(OK ERROR CANCEL)],
  storage => [map { "LIBMTP_STORAGE_SORTBY_$_" }
    qw(NOTSORTED FREESPACE MAXSPACE)],
);

$EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ];

#=====================================================================
# Package Return Value:

1;

__END__

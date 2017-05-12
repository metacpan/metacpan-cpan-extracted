package Mac::Spotlight::MDItem;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
# FIXME: We could auto-created these with AUTOLOAD but then how to get
# them into the caller's namespace?
our %EXPORT_TAGS = ( 'constants' => [ qw(
		        kMDItemAttributeChangeDate
			kMDItemAudiences
                        kMDItemAuthors
                        kMDItemCity
                        kMDItemComment
                        kMDItemContactKeywords
                        kMDItemContentCreationDate
                        kMDItemContentModificationDate
                        kMDItemContentType
                        kMDItemContributors
                        kMDItemCopyright
                        kMDItemCountry
                        kMDItemCoverage
                        kMDItemCreator
                        kMDItemDescription
                        kMDItemDueDate
                        kMDItemDurationSeconds
                        kMDItemEmailAddresses
                        kMDItemEncodingApplications
                        kMDItemFinderComment
                        kMDItemFonts
                        kMDItemHeadline
                        kMDItemIdentifier
                        kMDItemInstantMessageAddresses
                        kMDItemInstructions
                        kMDItemKeywords
                        kMDItemKind
                        kMDItemLanguages
                        kMDItemLastUsedDate
                        kMDItemNumberOfPages
                        kMDItemOrganizations
                        kMDItemPageHeight
                        kMDItemPageWidth
                        kMDItemPhoneNumbers
                        kMDItemProjects
                        kMDItemPublishers
                        kMDItemRecipients
                        kMDItemRights
                        kMDItemSecurityMethod
                        kMDItemStarRating
                        kMDItemStateOrProvince
                        kMDItemTextContent
                        kMDItemTitle
                        kMDItemVersion
                        kMDItemWhereFroms
                        kMDItemPixelHeight
                        kMDItemPixelWidth
                        kMDItemColorSpace
                        kMDItemBitsPerSample
                        kMDItemFlashOnOff
                        kMDItemFocalLength
                        kMDItemAcquisitionMake
                        kMDItemAcquisitionModel
                        kMDItemISOSpeed
                        kMDItemOrientation
                        kMDItemLayerNames
                        kMDItemWhiteBalance
                        kMDItemAperture
                        kMDItemProfileName
                        kMDItemResolutionWidthDPI
                        kMDItemResolutionHeightDPI
                        kMDItemExposureMode
                        kMDItemExposureTimeSeconds
                        kMDItemEXIFVersion
                        kMDItemAlbum
                        kMDItemHasAlphaChannel
                        kMDItemRedEyeOnOff
                        kMDItemMeteringMode
                        kMDItemMaxAperture
                        kMDItemFNumber
                        kMDItemExposureProgram
                        kMDItemExposureTimeString
                        kMDItemAudioBitRate
                        kMDItemCodecs
                        kMDItemDeliveryType
                        kMDItemMediaTypes
                        kMDItemStreamable
                        kMDItemTotalBitRate
                        kMDItemVideoBitRate
                        kMDItemAppleLoopDescriptors
                        kMDItemAppleLoopsKeyFilterType
                        kMDItemAppleLoopsLoopMode
                        kMDItemAppleLoopsRootKey
                        kMDItemAudioChannelCount
                        kMDItemAudioEncodingApplication
                        kMDItemAudioSampleRate
                        kMDItemAudioTrackNumber
                        kMDItemComposer
                        kMDItemIsGeneralMIDISequence
                        kMDItemKeySignature
                        kMDItemLyricist
                        kMDItemMusicalGenre
                        kMDItemMusicalInstrumentCategory
                        kMDItemMusicalInstrumentName
                        kMDItemRecordingDate
                        kMDItemRecordingYear
                        kMDItemTempo
                        kMDItemTimeSignature
                        kMDItemDisplayName
                        kMDItemFSContentChangeDate
                        kMDItemFSCreationDate
                        kMDItemFSExists
                        kMDItemFSInvisible
                        kMDItemFSIsExtensionHidden
                        kMDItemFSIsReadable
                        kMDItemFSIsWriteable
                        kMDItemFSLabel
                        kMDItemFSName
                        kMDItemFSNodeCount
                        kMDItemFSOwnerGroupID
                        kMDItemFSOwnerUserID
                        kMDItemFSSize
                        kMDItemPath
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'constants'} } );

our @EXPORT = qw();

our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Mac::Spotlight::MDItem', $VERSION);

sub new {
    my ($class, $path) = @_;
    my $mditem = _new($path) or return;
    bless { mdiObj => $mditem, _standalone => 1 }, $class;
}

sub get {
    my ($self, $attr) = @_;
    return _get($self->{mdiObj}, $attr);
}

sub DESTROY {
    my $self = shift;
    _destroy($self->{mdiObj}) if $self->{_standalone};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mac::Spotlight::MDItem - Examine the results of a Spotlight query

=head1 SYNOPSIS

  use Mac::Spotlight::MDItem ':constants';

  my $item = Mac::Spotlight::MDItem->new("/Users/miyagawa/Pictures/Hawaii.jpg");
  print $item->get(kMDItemKind), "\n"; # JPEG image

  use Mac::Spotlight::MDQuery ':constants';

  my $mdq = new Mac::Spotlight::MDQuery('kMDItemTitle == "*Battlestar*"c');
  $mdq->setScope(kMDQueryScopeComputer);

  $mdq->execute();
  $mdq->stop();

  my @results = $mdq->getResults();
  for my $r (@results) {
    print $r->get(kMDItemTitle), "\n";
    print $r->get(kMDItemKind), "\n";

    my $listref = $r->get(kMDItemAuthors);
    foreach $a (@$listref) {
      print "$a\n";
    }

    if ($r->get(kMDItemStreamable)) {
      print "Content is streamable\n";
    }
    print scalar localtime($r->get(kMDItemContentCreationDate)), "\n";
  }

=head1 DESCRIPTION

Mac::Spotlight is primarily accessed through two subpackages MDQuery
and MDItem. An MDQuery object is used to run a query and obtain the
results. The results are in a list containing zero or more MDItem
objects. This POD documents the methods of MDItem, including all of
the attributes which can be search criteria or search results. See the
POD for MDQuery for the details of setting up and executing a
Spotlight query.

=head1 METHODS

=over 4

=item C<get>

The result of calling MDQuery::getResults() is a list of zero or more
blessed MDItem objects. MDItem objects support only one method, get(),
but the things you can get with get() are many and varied.

get() takes one argument, which is a kMDItem* constant indicating the
attribute you wish to retrieve. The return value of get() is always a
single scalar. That scalar may be a string, a number, or a reference
depending on which attribute key you requested. An attribute key can
theoretically return anything but in practice the types of returned
values are limited to a handful.

For the complete list of MDItem attribute keys and what they return,
refer to L<http://developer.apple.com/documentation/Carbon/Reference/MDItemRef/Reference/chapter_1.3_section_1.html>. Check the EXPORTS section of this 
POD for a list of the attributes currently supported by
Mac::Spotlight. Below we describe how the returned Core Foundation
values are translated into Perl values. But first the rule: get()
returns undef IF AND ONLY IF the requested attribute does not exist
for this MDItem. undef is never a legitimate return value for an
attribute and undef does not signal an error. undef only means that
the requested attribute does not exist for this item. For example,
most files which are not songs or pictures will not have a
kMDItemAlbum.

If an attribute key is documented as returning a CFString, the scalar
returned by get() will contain a UTF-8 encoded string.

If an attribute key is documented as returning a CFDate, get() will
return a string which is the date formatted as if you had called
"scalar localtime($somevalue)" in Perl.

If an attribute key returns a CFNumber, get() will return a I<floating
point> value in the scalar.

If an attribute key returns a CFBoolean, get() will return either 1 or
0. Never undef! Remember the rule.

If an attribute key returns a CFArray, get() will return a reference
to an anonymous list which contains scalars translated according to
whether the CFArray held CFStrings, CFDates, etc.

=head2 EXPORT

None by default.

=head2 Exportable values

If you use the ":constants" tag when you use Mac::Spotlight::MDItem,
you will pull the kMDItem* constants into your current namespace. If
you chose not to you can still access the constants via their fully
qualified namespace.

Here is a list of all the currently defined kMDItem* constants. For a
description of what each one means, and what each returns, refer to
L<http://developer.apple.com/documentation/Carbon/Reference/MDItemRef/index.html>. If you see attributes on the web page which are not listed here,
Apple has added new attributes and Mac::Spotlight needs to catch up.

=over

=item kMDItemAttributeChangeDate

=item kMDItemAudiences

=item kMDItemAuthors

=item kMDItemCity

=item kMDItemComment

=item kMDItemContactKeywords

=item kMDItemContentCreationDate

=item kMDItemContentModificationDate

=item kMDItemContentType

=item kMDItemContributors

=item kMDItemCopyright

=item kMDItemCountry

=item kMDItemCoverage

=item kMDItemCreator

=item kMDItemDescription

=item kMDItemDueDate

=item kMDItemDurationSeconds

=item kMDItemEmailAddresses

=item kMDItemEncodingApplications

=item kMDItemFinderComment

=item kMDItemFonts

=item kMDItemHeadline

=item kMDItemIdentifier

=item kMDItemInstantMessageAddresses

=item kMDItemInstructions

=item kMDItemKeywords

=item kMDItemKind

=item kMDItemLanguages

=item kMDItemLastUsedDate

=item kMDItemNumberOfPages

=item kMDItemOrganizations

=item kMDItemPageHeight

=item kMDItemPageWidth

=item kMDItemPhoneNumbers

=item kMDItemProjects

=item kMDItemPublishers

=item kMDItemRecipients

=item kMDItemRights

=item MDItemSecurityMethod

=item kMDItemStarRating

=item kMDItemStateOrProvince

=item kMDItemTextContent

=item kMDItemTitle

=item kMDItemVersion

=item kMDItemWhereFroms

=item kMDItemPixelHeight

=item kMDItemPixelWidth

=item kMDItemColorSpace

=item kMDItemBitsPerSample

=item kMDItemFlashOnOff

=item kMDItemFocalLength

=item kMDItemAcquisitionMake

=item kMDItemAcquisitionModel

=item kMDItemISOSpeed

=item kMDItemOrientation

=item kMDItemLayerNames

=item kMDItemWhiteBalance

=item kMDItemAperture

=item kMDItemProfileName

=item kMDItemResolutionWidthDPI

=item kMDItemResolutionHeightDPI

=item kMDItemExposureMode

=item kMDItemExposureTimeSeconds

=item kMDItemEXIFVersion

=item kMDItemAlbum

=item kMDItemHasAlphaChannel

=item kMDItemRedEyeOnOff

=item kMDItemMeteringMode

=item kMDItemMaxAperture

=item kMDItemFNumber

=item kMDItemExposureProgram

=item kMDItemExposureTimeString

=item kMDItemAudioBitRate

=item kMDItemCodecs

=item kMDItemDeliveryType

=item kMDItemMediaTypes

=item kMDItemStreamable

=item kMDItemTotalBitRate

=item kMDItemVideoBitRate

=item kMDItemAppleLoopDescriptors

=item kMDItemAppleLoopsKeyFilterType

=item kMDItemAppleLoopsLoopMode

=item kMDItemAppleLoopsRootKey

=item kMDItemAudioChannelCount

=item kMDItemAudioEncodingApplication

=item kMDItemAudioSampleRate

=item kMDItemAudioTrackNumber

=item kMDItemComposer

=item kMDItemIsGeneralMIDISequence

=item kMDItemKeySignature

=item kMDItemLyricist

=item kMDItemMusicalGenre

=item kMDItemMusicalInstrumentCategory

=item kMDItemMusicalInstrumentName

=item kMDItemRecordingDate

=item kMDItemRecordingYear

=item kMDItemTempo

=item kMDItemTimeSignature

=item kMDItemDisplayName

=item kMDItemFSContentChangeDate

=item kMDItemFSCreationDate

=item kMDItemFSExists

=item kMDItemFSInvisible

=item kMDItemFSIsExtensionHidden

=item kMDItemFSIsReadable

=item kMDItemFSIsWriteable

=item kMDItemFSLabel

=item kMDItemFSName

=item kMDItemFSNodeCount

=item kMDItemFSOwnerGroupID

=item kMDItemFSOwnerUserID

=item kMDItemFSSize

=item kMDItemPath

=back

=head1 SEE ALSO

Mac::Spotlight::MDQuery

=head1 AUTHOR

Adrian Hosey, E<lt>alh@warhound.orgE<gt>

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Adrian Hosey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

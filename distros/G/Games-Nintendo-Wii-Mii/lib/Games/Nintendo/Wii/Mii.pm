package Games::Nintendo::Wii::Mii;

use strict;
use warnings;
use utf8;

use base qw(Class::Accessor::Fast);

use Carp qw(croak);
use Encode;
use File::Slurp qw(slurp);
use IO::File;
use Readonly;
use Tie::IxHash;
use URI;
use XML::LibXML;

use Games::Nintendo::Wii::Mii::Data::BeardMustache;
use Games::Nintendo::Wii::Mii::Data::Eye;
use Games::Nintendo::Wii::Mii::Data::Eyebrow;
use Games::Nintendo::Wii::Mii::Data::Face;
use Games::Nintendo::Wii::Mii::Data::Figure;
use Games::Nintendo::Wii::Mii::Data::Glasses;
use Games::Nintendo::Wii::Mii::Data::Hair;
use Games::Nintendo::Wii::Mii::Data::Mole;
use Games::Nintendo::Wii::Mii::Data::Mouth;
use Games::Nintendo::Wii::Mii::Data::Nose;
use Games::Nintendo::Wii::Mii::Data::Profile;

Readonly our @ACCESSORS => qw/
                                beard_mustache
                                eye
                                eyebrow
                                face
                                figure
                                glasses
                                hair
                                mole
                                mouth
                                nose
                                profile
                            /;

Readonly our $TYPE_UNKNOWN => 0;
Readonly our $TYPE_INTEGER => 1;
Readonly our $TYPE_STRING => 2;
Readonly our $TYPE_HEXADECIMAL => 3;

__PACKAGE__->mk_accessors(@ACCESSORS);

tie(
    our %STRUCT,
    'Tie::IxHash',
    (
        invalid => { size => 1, type => $TYPE_INTEGER, accessor => 'profile' },
        gender => { size => 1, type => $TYPE_INTEGER, accessor => 'profile', name => 'gender', min => 0, max => 1 },
        birth_month => { size => 4, type => $TYPE_INTEGER, accessor => 'profile', name => 'birthMonth', min => 0, max => 12 },
        birth_date => { size => 5, type => $TYPE_INTEGER, accessor => 'profile', name => 'birthDate', min => 0, max => 31 },
        favorite_color => { size => 4, type => $TYPE_INTEGER, accessor => 'profile', name => 'favoriteColor', min => 0, max => 11 },
        unknown_1 => { size => 1, type => $TYPE_UNKNOWN },

        name => { size => 160, type => $TYPE_STRING, accessor => 'profile' },
        height => { size => 8, type => $TYPE_INTEGER, accessor => 'figure', name => 'height', min => 0, max => 127 },
        weight => { size => 8, type => $TYPE_INTEGER, accessor => 'figure', name => 'weight', min => 0, max => 127 },
        mii_id => { size => 32, type => $TYPE_HEXADECIMAL, accessor => 'profile', name => 'id', min => '00-00-00-00', max => 'FF-FF-FF-FF' },
        system_id_checksum8 => { size => 8, type => $TYPE_HEXADECIMAL, accessor => 'profile', min => '00', max => 'FF' },
        system_id => { size => 24, type => $TYPE_HEXADECIMAL, accessor => 'profile', name => 'wii', min => '00-00-00', max => 'FF-FF-FF' },
        face_shape => { size => 3, type => $TYPE_INTEGER, accessor => 'face', name => 'headType', min => 0, max => 7 },
        skin_color => { size => 3, type => $TYPE_INTEGER, accessor => 'face', name => 'skinColor', min => 0, max => 5 },
        facial_feature => { size => 4, type => $TYPE_INTEGER, accessor => 'face', name => 'facialFeaturesType', min => 0, max => 15 },
        unknown_2 => { size => 3, type => $TYPE_UNKNOWN },
        mingle => { size => 1, type => $TYPE_INTEGER, accessor => 'profile', name => 'mingles', min => 0, max => 1 },
        unknown_3 => { size => 2, type => $TYPE_UNKNOWN },
            
        hair_type => { size => 7, type => $TYPE_INTEGER, accessor => 'hair', name => 'hairType', min => 0, max => 71 },
        hair_color => { size => 3, type => $TYPE_INTEGER, accessor => 'hair', name => 'hairColor', min => 0, max => 7 },
        hair_part => { size => 1, type => $TYPE_INTEGER, accessor => 'hair', name => 'hairPart', min => 0, max => 1 },
        unknown_4 => { size => 5, type => $TYPE_UNKNOWN },
            
        eyebrow_type => { size => 5, type => $TYPE_INTEGER, accessor => 'eyebrow', name => 'eyebrowType', min => 0, max => 23 },
        unknown_5 => { size => 1, type => $TYPE_UNKNOWN },
        eyebrow_rotation => { size => 4, type => $TYPE_INTEGER, accessor => 'eyebrow', name => 'eyebrowRotation', min => 0, max => 11 },
        unknown_6 => { size => 6, type => $TYPE_UNKNOWN },
        eyebrow_color => { size => 3, type => $TYPE_INTEGER, accessor => 'eyebrow', name => 'eyebrowColor', min => 0, max => 7 },
        eyebrow_size => { size => 4, type => $TYPE_INTEGER, accessor => 'eyebrow', name => 'eyebrowSize', min => 0, max => 8 },
        eyebrow_vertical_position => { size => 5, type => $TYPE_INTEGER, accessor => 'eyebrow', name => 'eyebrowY', min => 0, max => 15 },
        eyebrow_horizon_spacing => { size => 4, type => $TYPE_INTEGER, accessor => 'eyebrow', name => 'eyebrowX', min => 0, max => 12 },
            
        eye_type => { size => 6, type => $TYPE_INTEGER, accessor => 'eye', name => 'eyeType', min => 0, max => 47 },
        unknown_7 => { size => 2, type => $TYPE_UNKNOWN },
        eye_rotation => { size => 3, type => $TYPE_INTEGER, accessor => 'eye', name => 'eyeRotation', min => 0, max => 7 },
        eye_vertical_position => { size => 5, type => $TYPE_INTEGER, accessor => 'eye', name => 'eyeY', min => 0, max => 18 },
        eye_color => { size => 3, type => $TYPE_INTEGER, accessor => 'eye', name => 'eyeColor', min => 0, max => 5 },
        unknown_8 => { size => 1, type => $TYPE_UNKNOWN },
        eye_size => { size => 3, type => $TYPE_INTEGER, accessor => 'eye', name => 'eyeSize', min => 0, max => 7 },
        eye_horizon_spacing => { size => 4, type => $TYPE_INTEGER, accessor => 'eye', name => 'eyeX', min => 0, max => 12 },
        unknown_9 => { size => 5, type => $TYPE_UNKNOWN },
            
        nose_type => { size => 4, type => $TYPE_INTEGER, accessor => 'nose', name => 'noseType', min => 0, max => 11 },
        nose_size => { size => 4, type => $TYPE_INTEGER, accessor => 'nose', name => 'noseSize', min => 0, max => 8 },
        nose_vertical_position => { size => 5, type => $TYPE_INTEGER, accessor => 'nose', name => 'noseY', min => 0, max => 18 },
        unknown_10 => { size => 3, type => $TYPE_UNKNOWN },
            
        mouth_type => { size => 5, type => $TYPE_INTEGER, accessor => 'mouth', name => 'mouthType', min => 0, max => 23 },
        mouth_color => { size => 2, type => $TYPE_INTEGER, accessor => 'mouth', name => 'mouthColor', min => 0, max => 2 },
        mouth_size => { size => 4, type => $TYPE_INTEGER, accessor => 'mouth', name => 'mouthSize', min => 0, max => 8 },
        mouth_vertical_position => { size => 5, type => $TYPE_INTEGER, accessor => 'mouth', name => 'mouthY', min => 0, max => 18 },
            
        glasses_type => { size => 4, type => $TYPE_INTEGER, accessor => 'glasses', name => 'glassesType', min => 0, max => 8 },
        glasses_color => { size => 3, type => $TYPE_INTEGER, accessor => 'glasses', name => 'glassesColor', min => 0, max => 5 },
        unknown_11 => { size => 1, type => $TYPE_UNKNOWN },
        glasses_size => { size => 3, type => $TYPE_INTEGER, accessor => 'glasses', name => 'glassesSize', min => 0, max => 7 },
        glasses_vertical_position => { size => 5, type => $TYPE_INTEGER, accessor => 'glasses', name => 'glassesY', min => 0, max => 20 },
            
        mustache_type => { size => 2, type => $TYPE_INTEGER, accessor => 'beard_mustache', name => 'mustacheType', min => 0, max => 3 },
        beard_type => { size => 2, type => $TYPE_INTEGER, accessor => 'beard_mustache', name => 'beardType', min => 0, max => 3 },
        facial_hair_color => { size => 3, type => $TYPE_INTEGER, accessor => 'beard_mustache', name => 'facialHairColor', min => 0, max => 7 },
        mustache_size => { size => 4, type => $TYPE_INTEGER, accessor => 'beard_mustache', name => 'mustacheSize', min => 0, max => 8 },
        unknown_12 => { size => 1, type => $TYPE_UNKNOWN },
        mustache_vertical_position => { size => 4, type => $TYPE_INTEGER, accessor => 'beard_mustache', name => 'mustacheY', min => 0, max => 16 },
            
        mole_on => { size => 1, type => $TYPE_INTEGER, accessor => 'mole', name => 'moleType', min => 0, max => 1 },
        mole_size => { size => 4, type => $TYPE_INTEGER, accessor => 'mole', name => 'moleSize', min => 0, max => 15 },
        mole_vertical_position => { size => 5, type => $TYPE_INTEGER, accessor => 'mole', name => 'moleX', min => 0, max => 30 },
        mole_horizon_position => { size => 5, type => $TYPE_INTEGER, accessor => 'mole', name => 'moleY', min => 0, max => 16 },
        unknown_13 => { size => 1, type => $TYPE_UNKNOWN },
            
        creator_name => { size => 160, type => $TYPE_STRING, accessor => 'profile' }
    )
);

=head1 NAME

Games::Nintendo::Wii::Mii - Mii in Nintendo Wii data parser and builder.

=head1 VERSION

version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Games::Nintendo::Wii::Mii;
    
    my $mii = Games::Nintendo::Wii::Mii->new;
    
    $mii->parse_from_file('zigorou.mii');
    $mii->profile->name("ZIGOROU");
    $mii->profile->creator_name("TORU");
    $mii->save_to_file("new_zigorou.mii");
    print $mii->to_xml();

=head1 METHODS

=head2 new()

Constructor.

=cut

sub new {
    my $class = shift;

    my $prefix = "Games::Nintendo::Wii::Mii::Data::";
    my $self = $class->SUPER::new();
    
    for my $accessor (@ACCESSORS) {
        my $package = $prefix . join("", map { ucfirst } split(/_/, $accessor));
        $self->$accessor($package->new);
    }

    return $self;
}

=head2 parse_from_file($filename)

Parse mii data from mii binary file.

=cut

sub parse_from_file {
    my ($self, $filename) = @_;

    ### TODO : validation

    $self->parse_from_binary(slurp($filename));
}

=head2 parse_from_binary($binary)

Parse mii data from mii binary.

=cut

sub parse_from_binary {
    my ($self, $binary) = @_;

    my $bits = unpack("B*", $binary);
    my %data = ();
    my $index = 0;

    foreach my $key (keys %STRUCT) {
        $data{$key} = substr($bits, $index, $STRUCT{$key}->{size});

        my $type = $STRUCT{$key}->{type};

        if ($type == $TYPE_INTEGER) {
            $data{$key} = oct("0b$data{$key}");
        }
        elsif ($type == $TYPE_STRING) {
            $data{$key} = decode("UTF16BE", pack("B*", $data{$key}));
            $data{$key} =~ s/\x00*$//; ### erase end of spaces and null bytes
        }
        elsif ($type == $TYPE_HEXADECIMAL) {
            $data{$key} = join("-", map { uc } unpack("H2" x ( $STRUCT{$key}->{size} / 8), pack("B*", $data{$key})));
        }
        else {
            ### unknown data
        }

        $index += $STRUCT{$key}->{size};
    }

    ### TODO : validation

    for my $part (@ACCESSORS) {
        no strict 'refs';
        for my $accessor (@{ref($self->$part()) . "::ACCESSORS"}) {
            $self->$part->$accessor($data{$accessor});
        }
    }

    return 1;
}

=head2 parse_from_hex($hex)

Parse mii data from mii binary hexdump.

=cut

sub parse_from_hex {
    my ($self, $hex) = @_;

    $self->parse_from_binary(pack("H*", $hex));
}

=head2 parse_from_xml_file($xml_file)

Parse mii data from xml file.

=cut

sub parse_from_xml_file {
    my ($self, $xml_file) = @_;

    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_file($xml_file);

    $self->parse_from_xml($doc);
}

=head2 parse_from_xml_string($xml_string)

Parse mii data from xml string.

=cut

sub parse_from_xml_string {
    my ($self, $xml_string) = @_;

    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_string($xml_string);

    $self->parse_from_xml($doc);
}

=head2 parse_from_xml($doc)

Parse mii data from xml document object (See L<XML::LibXML::Document>)

=cut

sub parse_from_xml {
    my ($self, $doc) = @_;

    my $xpc = XML::LibXML::XPathContext->new($doc);
    croak("Not valid mii's xml") unless ($xpc->find('//mii[@value]/@value'));

    $self->parse_from_hex($xpc->find('//mii[@value]/@value'));
}

=head2 save_to_file($filename)

Save mii binary to file.

=cut

sub save_to_file {
    my ($self, $filename) = @_;

    my $fh = IO::File->new("> $filename") || croak(qq|Can't open file : | . $filename);
    syswrite($fh, $self->to_binary());
    $fh->close;
}

=head2 save_to_xml_file($filename)

Save mii xml to file.

=cut

sub save_to_xml_file {
    my ($self, $filename) = @_;

    my $fh = IO::File->new("> $filename") || croak(qq|Can't open file : | . $filename);
    print $fh $self->to_xml;
    $fh->close;
}

=head2 to_binary()

To binary data.

=cut

sub to_binary {
    my $self = shift;

    pack("H*", $self->to_hexdump);
}

=head2 to_hexdump()

To hexdump.

=cut

sub to_hexdump {
    my $self = shift;
    my $bits = '';

    for my $key (keys %STRUCT) {
        my $type = $STRUCT{$key}->{type};

        if ($type == $TYPE_UNKNOWN) {
            $bits .= '0' x $STRUCT{$key}->{size};
            next;
        }

        my $accessor = $STRUCT{$key}->{accessor};

        ### TODO : adhoc
        warn("$key is not defined accessor") unless ($accessor);

        my $value = $self->$accessor->$key();
        my $size = $STRUCT{$key}->{size};

        if ($type == $TYPE_INTEGER) {
            $bits .= substr(unpack("B8", pack("C", $value)), 8 - $size, $size);
        }
        elsif ($type == $TYPE_STRING) {
            my $strhex = unpack("H*", encode("UTF16BE", $value));
            $strhex .= '0' x (($size / 8 * 2) - length $strhex);
            $bits .= unpack("B*", pack("H*", $strhex));
        }
        else { ### $TYPE_HEXADECIMAL
            my @pieces = split(/-/, $value);
            $bits .= substr(unpack("B*", pack("H2" x (scalar @pieces), @pieces)), 8 * (scalar @pieces) - $size, $size);
        }
    }

    return unpack("H*", pack("B*", $bits));
}

=head2 to_xml()

To xml.

=cut

sub to_xml {
    my $self = shift;

    my $doc = XML::LibXML::Document->new('1.0');
    my $pinode = $doc->createProcessingInstruction('xml-stylesheet');
    $pinode->setData(type => 'text/xsl', href => 'http://www.miieditor.com/xml/mii.xsl');
    $doc->appendChild($pinode);

    my $root = $doc->createElement('mii-collection');
    $doc->setDocumentElement($root);

    my $dtd = $doc->createInternalSubset($root->tagName, undef, 'http://www.miieditor.com/xml/mii.dtd');
    $doc->setInternalSubset($dtd);

    my $mii_element = $doc->createElement('mii');
    $mii_element->setAttribute('value', $self->to_hexdump);
    $root->appendChild($mii_element);

    my $name_element = $doc->createElement('name');
    my $creator_element = $doc->createElement('creator');

    $name_element->setAttribute('maxChars', 10);
    $creator_element->setAttribute('maxChars', 10);

    $name_element->appendText(encode('utf8', $self->profile->name));
    $creator_element->appendText(encode('utf8', $self->profile->creator_name));

    $mii_element->appendChild($name_element);
    $mii_element->appendChild($creator_element);

    my $data_element = $doc->createElement('data');

    my %formats = (
        $TYPE_INTEGER => 'integer',
        $TYPE_HEXADECIMAL => 'hexadecimal'
    );

    {
        no strict 'refs';

        for my $key (sort { $STRUCT{$a}->{name} cmp $STRUCT{$b}->{name} } grep {exists $STRUCT{$_}->{name}} keys %STRUCT) {
            my $data_clone = $data_element->cloneNode();
            my $accessor = $STRUCT{$key}->{accessor};

            $data_clone->setAttribute('name', $STRUCT{$key}->{name});
            $data_clone->setAttribute('value', $self->$accessor->$key);
            $data_clone->setAttribute('format', $formats{$STRUCT{$key}->{type}});

            $data_clone->setAttribute('min', $STRUCT{$key}->{min});
            $data_clone->setAttribute('max', $STRUCT{$key}->{max});

            $mii_element->appendChild($data_clone);
        }
    }

    return $doc->toString(1);
}

=head2 to_edit_url()

To online editable url powered by MiiEditor http://www.miieditor.com/

=cut

sub to_edit_url {
    my $self = shift;

    my $uri = URI->new("http://miieditor.com/");
    $uri->query_form(
        mii => $self->to_hexdump
    );

    return $uri->as_string;
}

=head2 to_view_url()

To online viewable url powered by MiiEditor http://www.miieditor.com/

=cut

sub to_view_url {
    my $self = shift;

    my $uri = URI->new("http://www.miieditor.com/");
    $uri->path('view.php');
    $uri->query_form(
        mii => $self->to_hexdump
    );

    return $uri->as_string;
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 SEE ALSO

=over 4

=item Mii Data Structure

Describe mii data format, see below.

   http://wiibrew.org/index.php?title=Wiimote/Mii_Data

=item Mii Editor

Online mii data editor created by flash and php.

   http://www.miieditor.com/

This module use DTD and editor, viewer created by miieditor.com.
Thanks a lot.

=item L<Carp>

=item L<Encode>

=item L<File::Slurp>

=item L<IO::File>

=item L<Readonly>

=item L<Tie::IxHash>

=item L<URI>

=item L<XML::LibXML>

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-nintendo-wii-mii@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Games::Nintendo::Wii::Mii

__END__

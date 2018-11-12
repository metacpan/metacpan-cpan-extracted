package Geo::GDAL::FFI::Object;
use v5.10;
use strict;
use warnings;
use Carp;

our $VERSION = 0.0601;

sub GetDescription {
    my $self = shift;
    return Geo::GDAL::FFI::GDALGetDescription($$self);
}

sub HasCapability {
    my ($self, $cap) = @_;
    my $tmp = $Geo::GDAL::FFI::capabilities{$cap};
    confess "Unknown capability: $cap." unless defined $tmp;
    my $md = $self->GetMetadata('');
    return $md->{'DCAP_'.$cap};
}

sub GetMetadataDomainList {
    my ($self) = @_;
    my $csl = Geo::GDAL::FFI::GDALGetMetadataDomainList($$self);
    my @list;
    for my $i (0..Geo::GDAL::FFI::CSLCount($csl)-1) {
        push @list, Geo::GDAL::FFI::CSLGetField($csl, $i);
    }
    Geo::GDAL::FFI::CSLDestroy($csl);
    return wantarray ? @list : \@list;
}

sub GetMetadata {
    my ($self, $domain) = @_;
    my %md;
    unless (defined $domain) {
        for $domain ($self->GetMetadataDomainList) {
            $md{$domain} = $self->GetMetadata($domain);
        }
        return wantarray ? %md : \%md;
    }
    my $csl = Geo::GDAL::FFI::GDALGetMetadata($$self, $domain);
    for my $i (0..Geo::GDAL::FFI::CSLCount($csl)-1) {
        my ($name, $value) = split /=/, Geo::GDAL::FFI::CSLGetField($csl, $i);
        $md{$name} = $value;
    }
    return wantarray ? %md : \%md;
}

sub SetMetadata {
    my ($self, $metadata, $domain) = @_;
    unless (defined $domain) {
        for $domain (keys %$metadata) {
            $self->SetMetadata($metadata->{$domain}, $domain);
        }
    } else {
        my $csl = 0;
        for my $name (keys %$metadata) {
            $csl = Geo::GDAL::FFI::CSLAddString($csl, "$name=$metadata->{$name}");
        }
        my $err = Geo::GDAL::FFI::GDALSetMetadata($$self, $csl, $domain);
        Geo::GDAL::FFI::CSLDestroy($csl);
        confess Geo::GDAL::FFI::error_msg() if $err == $Geo::GDAL::FFI::Failure;
        warn Geo::GDAL::FFI::error_msg() if $err == $Geo::GDAL::FFI::Warning;
    }
}

sub GetMetadataItem {
    my ($self, $name, $domain) = @_;
    $domain //= "";
    return Geo::GDAL::FFI::GDALGetMetadataItem($$self, $name, $domain);
}

sub SetMetadataItem {
    my ($self, $name, $value, $domain) = @_;
    $domain //= "";
    my $err = Geo::GDAL::FFI::GDALSetMetadataItem($$self, $name, $value, $domain);
    confess Geo::GDAL::FFI::error_msg() if $err == $Geo::GDAL::FFI::Failure;
    warn Geo::GDAL::FFI::error_msg() if $err == $Geo::GDAL::FFI::Warning;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::Object - A GDAL major object

=head1 SYNOPSIS

=head1 DESCRIPTION

The base class for classes Driver, Dataset, Band, and Layer.

=head1 METHODS

=head2 GetDescription

 my $desc = $object->GetDescription;

=head2 HasCapability

 my $has_cap = $object->HasCapability($capability);

=head2 GetMetadataDomainList

 my @domains = $object->GetMetadataDomainList;

=head2 GetMetadata

 my %metadata = $object->GetMetadata($domain);

Returns the object metadata of a given domain.

 my $metadata = $object->GetMetadata($domain);

Returns the object metadata of a given domain in an anonymous hash.

 my %metadata = $object->GetMetadata;

Returns the object metadata.

 my $metadata = $object->GetMetadata;

Returns the object metadata in an anonymous hash.

=head2 SetMetadata

 $object->SetMetadata($metadata, $domain);

Sets the object metadata in a given domain. The metadata is in an
anonymous hash.

 $object->SetMetadata($metadata);

Sets the object metadata in the domains that are the keys of the hash
$metadata references. The values of the hash are the metadata in
anonymous hashes.

=head2 GetMetadataItem

 my $value = $object->GetMetadataItem($item, $domain)

Gets the value of the metadata item in a domain (by default an empty
string).

=head2 SetMetadataItem

 $object->GetMetadataItem($item, $value, $domain)

Sets the value of the metadata item in a domain (by default an empty
string).

=head1 LICENSE

This software is released under the Artistic License. See
L<perlartistic>.

=head1 AUTHOR

Ari Jolma - Ari.Jolma at gmail.com

=head1 SEE ALSO

L<Geo::GDAL::FFI>

L<Alien::gdal>, L<FFI::Platypus>, L<http://www.gdal.org>

=cut

__END__;

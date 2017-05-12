package Geo::UK::Postcode;

use Moo;
use MooX::Aliases;

use base 'Exporter';
use Geo::UK::Postcode::Regex;

use overload '""' => "as_string";

our $VERSION = '0.010';

our @EXPORT_OK = qw/ pc_sort /;

=encoding utf-8

=head1 NAME

Geo::UK::Postcode - Object and class methods for working with British postcodes.

=head1 SYNOPSIS

    # See Geo::UK::Postcode::Regex for parsing/matching postcodes

    use Geo::UK::Postcode;

    my $pc = Geo::UK::Postcode->new("wc1h9eb");

    $pc->raw;             # wc1h9eb - as entered
    $pc->as_string;       # WC1H 9EB - output in correct format
    "$pc";                # stringifies, same output as '->as_string'
    $pc->fixed_format;    # 8 characters, the incode always last three

    $pc->area;            # WC
    $pc->district;        # 1
    $pc->subdistrict;     # H
    $pc->sector;          # 9
    $pc->unit;            # EB

    $pc->outcode;         # WC1H
    $pc->incode;          # 9EB

    $pc->strict;          # true if matches strict regex
    $pc->valid;           # true if matches strict regex and has a valid outcode
    $pc->partial;         # true if postcode is for a district or sector only

    $pc->non_geographical;    # true if outcode is known to be
                              # non-geographical

    $pc->bfpo;                # true if postcode is for a BFPO address

    my @posttowns = $pc->posttowns;    # list of one or more 'post towns'
                                       # associated with this postcode

    # Sort Postcode objects:
    use Geo::UK::Postcode qw/ pc_sort /;

    my @sorted_pcs = sort pc_sort @unsorted_pcs;

=head1 DESCRIPTION

An object to represent a British postcode.

For matching and parsing postcodes in a non-OO manner without the L<Moo>
dependency (for form validation, for example), see L<Geo::UK::Postcode::Regex>
or L<Geo::UK::Postcode::Regex::Simple>.

For geo-location (finding latitude and longitude) see
L</"GEO-LOCATING POSTCODES">.

=head1 ATTRIBUTES

=head2 raw

The exact string that the object was constructed from, without formatting.

=cut

has raw => (
    is  => 'ro',
    isa => sub {
        die "Empty or invalid value passed to 'raw'" unless $_[0] && !ref $_[0];
    },
);

=for Pod::Coverage BUILDARGS BUILD components

=cut

# private - hashref to hold parsed components of postcode
has components => (
    is      => 'rwp',
    default => sub { {} },
);

around BUILDARGS => sub {
    my ( $orig, $class, $args ) = @_;

    return $class->$orig(    #
        ref $args ? $args : { raw => $args }
    );
};

sub BUILD {
    my ($self) = @_;

    my $pc = uc $self->raw;

    my $parsed = Geo::UK::Postcode::Regex->parse( $pc, { partial => 1 } )
        or die sprintf( "Unable to parse '%s' as a postcode", $self->raw );

    $self->_set_components($parsed);
}

=head1 METHODS

=head2 raw


=head2 as_string

    $pc->as_string;

    # or:

    "$pc";

Stringification of postcode object, returns postcode with a single space
between outcode and incode.

=cut

sub as_string { $_[0]->outcode . ( $_[0]->incode ? ' ' . $_[0]->incode : '' ) }

=head2 fixed_format

    my $fixed_format = $postcode->fixed_format;

Returns the full postcode in a fixed length (8 character) format, with extra
padding spaces inserted as necessary.

=cut

sub fixed_format {
    sprintf( "%-4s %-3s", $_[0]->outcode, $_[0]->incode );
}

=head2 area, district, subdistrict, sector, unit

Return the corresponding part of the postcode, undef if not present.

=cut

sub area        { shift->components->{area} }
sub district    { shift->components->{district} }
sub subdistrict { shift->components->{subdistrict} }
sub sector      { shift->components->{sector} }
sub unit        { shift->components->{unit} }

=head2 outcode

The first half of the postcode, before the space - comprises of the area and
district.

=head2 incode

The second half of the postcode, after the space - comprises of the sector
and unit. Returns an empty string if not present.

=cut

sub outcode {
    $_[0]->area . $_[0]->district . ( $_[0]->subdistrict || '' );
}

sub incode {
    ( $_[0]->sector // '' ) . ( $_[0]->unit || '' );
}

=head2 outward, inward

Aliases for C<outcode> and C<incode>.

=cut

alias outward => 'outcode';
alias inward  => 'incode';

=head2 valid

    if ($pc->valid) {
        ...
    }

Returns true if postcode has valid outcode and matches strict regex.

=head2 partial

    if ($pc->partial) {
      ...
    }

Returns true if postcode is not a full postcode, either a postcode district
( e . g . AB10 )
or postcode sector (e.g. AB10 1).

=head2 strict

    if ($pc->strict) {
      ...
    }

Returns true if postcode matches strict regex, meaning all characters are valid
( although postcode might not exist ) .

=cut

sub valid {
    $_[0]->components->{valid} ? 1 : 0;
}

sub partial {
    $_[0]->components->{partial} ? 1 : 0;
}

sub strict {
    $_[0]->components->{strict} ? 1 : 0;
}

=head2 non_geographical

    if ($pc->non_geographical) {
      ...
    }

Returns true if the outcode is known to be non-geographical. Note that
geographical outcodes may have non-geographical postcodes within them.

(Non-geographical postcodes are used for PO Boxes, or organisations
receiving large amounts of post).

=cut

sub non_geographical {
    $_[0]->components->{non_geographical} ? 1 : 0;
}

=head2 bfpo

    if ($pc->bfpo) {
        ...
    }

Returns true if postcode is mapped to a BFPO number (British Forces Post
Office).

=cut

sub bfpo {
    $_[0]->outcode eq 'BF1' ? 1 : 0;
}

=head2 posttowns

    my (@posttowns) = $postcode->posttowns;

Returns list of one or more 'post towns' that this postcode is assigned to.

Post towns are rarely used today, and are no longer required in a postal address
but are included with the postcode data, so provided here.

=cut

sub posttowns {
    Geo::UK::Postcode::Regex->outcode_to_posttowns( $_[0]->outcode );
}

=head1 EXPORTABLE

=head2 pc_sort

    my @sorted_pcs = sort pc_sort @unsorted_pcs;

Exportable sort function, sorts postcode objects in a useful manner. The
sort is in the following order: area, district, subdistrict, sector, unit
(ascending alphabetical or numerical order as appropriate).

=cut

sub pc_sort($$) {
           $_[0]->area cmp $_[1]->area
        || $_[0]->district <=> $_[1]->district
        || ( $_[0]->subdistrict || '' ) cmp( $_[1]->subdistrict || '' )
        || ( $_[0]->incode || '' ) cmp( $_[1]->incode || '' );
}

1;

__END__

=head1 GEO-LOCATING POSTCODES

Postcodes can be geolocated by obtaining the Ordnance Survey 'Code-Point' data
(or the free 'Code-Point Open' data).

For full details of using this class with Code-Point data, see:
L<Geo::UK::Postcode::Manual::Geolocation>.

=head1 SEE ALSO

=over

=item *

L<Geo::UK::Postcode::Regex>

=item *

L<Geo::Address::Mail::UK>

=item *

L<Geo::Postcode>

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/mjemmeson/geo-uk-postcode/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mjemmeson/geo-uk-postcode>

    git clone git://github.com/mjemmeson/geo-uk-postcode.git

=head1 AUTHOR

Michael Jemmeson E<lt>mjemmeson@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Michael Jemmeson

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


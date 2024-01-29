package GDPR::IAB::TCFv2::RangeSection;
use strict;
use warnings;
use integer;
use bytes;

use GDPR::IAB::TCFv2::BitUtils qw<is_set get_uint12 get_uint16>;
use Carp                       qw<croak>;

sub Parse {
    my ( $klass, %args ) = @_;

    croak "missing 'data'"      unless defined $args{data};
    croak "missing 'data_size'" unless defined $args{data_size};
    croak "missing 'offset'"    unless defined $args{offset};
    croak "missing 'max_id'"
      unless defined $args{max_id};

    croak "missing 'options'"      unless defined $args{options};
    croak "missing 'options.json'" unless defined $args{options}->{json};

    my $data      = $args{data};
    my $data_size = $args{data_size};
    my $offset    = $args{offset};
    my $max_id    = $args{max_id};
    my $options   = $args{options};

    Carp::confess
      "a BitField for vendor consent strings using RangeSections require at least 31 bytes. Got $data_size"
      if $data_size < 31;

    my %prefetch;
    my %cache;

    if ( exists $options->{prefetch} ) {
        my $vendor_ids = $options->{prefetch};

        foreach my $vendor_id ( @{$vendor_ids} ) {
            $prefetch{$vendor_id} = 1;
            $cache{$vendor_id}    = 0;
        }
    }

    my $self = {
        ranges  => [],
        cache   => \%cache,
        max_id  => $max_id,
        options => $options,
    };

    bless $self, $klass;

    my $next_offset = $self->_parse( $data, $data_size, $offset, \%prefetch );

    return ( $self, $next_offset );
}

sub _parse {
    my ( $self, $data, $data_size, $offset, $prefetch ) = @_;

    my ( $num_entries, $next_offset ) = get_uint12( $data, $offset );

    foreach my $i ( 1 .. $num_entries ) {
        $next_offset = $self->_parse_range(
            $data,
            $data_size,
            $next_offset,
            $prefetch,
        );
    }

    return $next_offset;
}

sub _parse_range {
    my ( $self, $data, $data_size, $offset, $prefetch ) = @_;

    croak
      "bit $offset was suppose to start a new range entry, but the consent string was only $data_size bytes long"
      if $data_size <= $offset / 8;

    my $max_id = $self->{max_id};

    # If the first bit is set, it's a Range of IDs
    my ( $is_range, $next_offset ) = is_set $data, $offset;
    if ($is_range) {
        my ( $start, $end );

        ( $start, $next_offset ) = get_uint16( $data, $next_offset );
        ( $end,   $next_offset ) = get_uint16( $data, $next_offset );

        croak
          "bit $offset range entry exclusion starts at $start, but the min vendor ID is 1"
          if 1 > $start;

        croak
          "bit $offset range entry exclusion ends at $end, but the max vendor ID is $max_id"
          if $end > $max_id;

        croak "start $start can't be bigger than end $end" if $start > $end;

        push @{ $self->{ranges} }, [ $start, $end ];

        foreach my $vendor_id ( keys %{$prefetch} ) {
            $self->{cache}->{$vendor_id} = delete( $prefetch->{$vendor_id} )
              if $start <= $vendor_id && $vendor_id <= $end;
        }

        return $next_offset;
    }

    my $vendor_id;

    ( $vendor_id, $next_offset ) = get_uint16( $data, $next_offset );

    croak
      "bit $offset range entry exclusion vendor $vendor_id, but only vendors [1, $max_id] are valid"
      if 1 > $vendor_id || $vendor_id > $max_id;

    push @{ $self->{ranges} }, [ $vendor_id, $vendor_id ];

    $self->{cache}->{$vendor_id} = delete( $prefetch->{$vendor_id} )
      if exists $prefetch->{$vendor_id};

    return $next_offset;
}

sub max_id {
    my $self = shift;

    return $self->{max_id};
}

sub contains {
    my ( $self, $id ) = @_;

    croak "invalid vendor id $id: must be positive integer bigger than 0"
      if $id < 1;

    return $self->{cache}->{$id} if exists $self->{cache}->{$id};

    return if $id > $self->{max_id};

    foreach my $range ( @{ $self->{ranges} } ) {
        return 1 if $range->[0] <= $id && $id <= $range->[1];
    }

    return 0;
}

sub all {
    my $self = shift;

    my @vendors;
    foreach my $range ( @{ $self->{ranges} } ) {
        push @vendors, $range->[0] .. $range->[1];
    }

    return \@vendors;
}

sub TO_JSON {
    my $self = shift;

    return $self->all if !!$self->{options}->{json}->{compact};

    my ( $false, $true ) = @{ $self->{options}->{json}->{boolean_values} };

    my %map;
    if ( !!$self->{options}->{json}->{verbose} ) {
        %map = map { $_ => $false } 1 .. $self->{max_id};
    }

    foreach my $range ( @{ $self->{ranges} } ) {
        %map = ( %map, map { $_ => $true } $range->[0] .. $range->[1] );
    }

    return \%map;
}

1;
__END__

=head1 NAME

GDPR::IAB::TCFv2::RangeSection - Transparency & Consent String version 2 range section parser

=head1 SYNOPSIS

    my $data = unpack "B*", decode_base64url('tcf v2 consent string base64 encoded');
    
    my $max_id_consent = << get 16 bits from $data offset 213 >>

    my ($range_section, $next_offset) = GDPR::IAB::TCFv2::RangeSection->Parse(
        data      => $data,
        data_size => length($data),
        offset    => 230,             # offset for vendor ranges
        max_id    => $max_id_consent,
        prefetch  => 284,             # will cache the result of vendor id 284
    );

    say "range section contains id 284" if $range_section->contains(284);

=head1 CONSTRUCTOR

Constructor C<Parse> receives an hash parameters: 

=over

=item *

Key C<data> is the binary data

=item *

Key C<data_size> is the original binary data size

=item *

Key C<offset> is the binary data offset. Can be 0.

=item *

Key C<max_id> is the max id (used to validate the ranges if all data is between 1 and  C<max_id>)

=item *

Key C<options> is the L<GDPR::IAB::TCFv2> options (includes the C<json> field to modify the L</TO_JSON> method output.

=item *

Key C<prefetch> is an optional arrayref of vendor ids to populate the result as cache.

=back

Will die if any parameter is missing.

Will die if data does not contain all bits required.

Will die if the range sections are malformed.

Will return an array of two elements: the object itself and the next offset.

=head1 METHODS

=head2 contains

Return the vendor id bit status (if enable or not) from one of the range sections.

Will return false if id is bigger than max vendor id.

    my $ok = $range_section->contains(284);

=head2 max_id

Returns the max vendor id.

=head2 all

Returns an arrayref of all vendors mapped with the bit enabled.

=head2 TO_JSON

By default it returns an hashref mapping id to a boolean, that represent if the id is present or not in all ranges sections.

The json option C<verbose> controls if all ids between 1 to L</max_id> will be present on the C<json> or only the ones that are true.

The json option C<compact> change the response, will return an arrayref of all ids present on the ranges section.

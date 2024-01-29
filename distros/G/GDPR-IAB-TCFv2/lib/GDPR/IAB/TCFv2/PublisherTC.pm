package GDPR::IAB::TCFv2::PublisherTC;
use strict;
use warnings;

use Carp qw<croak>;

use GDPR::IAB::TCFv2::BitUtils qw<is_set
  get_uint3
  get_uint6
>;

use constant {
    SEGMENT_TYPE_PUBLISHER_TC => 3,
    MAX_PURPOSE_ID            => 24,
    OFFSETS                   => {
        SEGMENT_TYPE            => 0,
        PURPOSE_CONSENT_ALLOWED => 3,
        PURPOSE_LIT_ALLOWED     => 27,
        NUM_CUSTOM_PURPOSES     => 51,
        CUSTOM_PURPOSES_CONSENT => 57,
    },
};

sub Parse {
    my ( $klass, %args ) = @_;

    croak "missing 'data'"      unless defined $args{data};
    croak "missing 'data_size'" unless defined $args{data_size};

    croak "missing 'options'"      unless defined $args{options};
    croak "missing 'options.json'" unless defined $args{options}->{json};

    my $data      = $args{data};
    my $data_size = $args{data_size};
    my $options   = $args{options};

    croak "invalid min size" if $data_size < 57;

    my $segment_type = get_uint3( $data, OFFSETS->{SEGMENT_TYPE} );

    croak
      "invalid segment type ${segment_type}: expected @{[ SEGMENT_TYPE_PUBLISHER_TC ]}"
      if $segment_type != SEGMENT_TYPE_PUBLISHER_TC;

    my $num_custom_purposes =
      get_uint6( $data, OFFSETS->{NUM_CUSTOM_PURPOSES} );

    my $total_expected_size = 2 * $num_custom_purposes + 57;

    croak "invalid size" if $data_size < $total_expected_size;

    my $self = {
        data                      => $data,
        options                   => $options,
        num_custom_purposes       => $num_custom_purposes,
        custom_purpose_lit_offset => OFFSETS->{CUSTOM_PURPOSES_CONSENT}
          + $num_custom_purposes,
    };

    bless $self, $klass;

    return $self;
}

sub num_custom_purposes {
    my $self = shift;

    return $self->{num_custom_purposes};
}

sub is_purpose_consent_allowed {
    my ( $self, $id ) = @_;

    croak "invalid purpose id $id: must be between 1 and @{[ MAX_PURPOSE_ID ]}"
      if $id < 1 || $id > MAX_PURPOSE_ID;

    return $self->_safe_is_purpose_consent_allowed($id);
}

sub is_purpose_legitimate_interest_allowed {
    my ( $self, $id ) = @_;

    croak "invalid purpose id $id: must be between 1 and @{[ MAX_PURPOSE_ID ]}"
      if $id < 1 || $id > MAX_PURPOSE_ID;

    return $self->_safe_is_purpose_legitimate_interest_allowed($id);
}

sub is_custom_purpose_consent_allowed {
    my ( $self, $id ) = @_;

    croak
      "invalid custom purpose id $id: must be between 1 and @{[ $self->{num_custom_purposes} ]}"
      if $id < 1 || $id > $self->{num_custom_purposes};

    return $self->_safe_is_custom_purpose_consent_allowed($id);
}

sub is_custom_purpose_legitimate_interest_allowed {
    my ( $self, $id ) = @_;

    croak
      "invalid custom purpose id $id: must be between 1 and @{[ $self->{num_custom_purposes} ]}"
      if $id < 1 || $id > $self->{num_custom_purposes};

    return $self->_safe_is_custom_purpose_legitimate_interest_allowed($id);
}

sub TO_JSON {
    my $self = shift;

    my %consents = map { $_ => $self->_safe_is_purpose_consent_allowed($_) }
      1 .. MAX_PURPOSE_ID;
    my %legitimate_interests =
      map { $_ => $self->_safe_is_purpose_legitimate_interest_allowed($_) }
      1 .. MAX_PURPOSE_ID;
    my %custom_purpose_consents =
      map { $_ => $self->_safe_is_custom_purpose_consent_allowed($_) }
      1 .. $self->{num_custom_purposes};
    my %custom_purpose_legitimate_interests = map {
        $_ => $self->_safe_is_custom_purpose_legitimate_interest_allowed($_)
    } 1 .. $self->{num_custom_purposes};

    return {
        consents =>
          $self->_format_json_subsection( \%consents, MAX_PURPOSE_ID ),
        legitimate_interests => $self->_format_json_subsection(
            \%legitimate_interests, MAX_PURPOSE_ID
        ),
        custom_purposes => {
            consents => $self->_format_json_subsection(
                \%custom_purpose_consents, $self->{num_custom_purposes}
            ),
            legitimate_interests => $self->_format_json_subsection(
                \%custom_purpose_legitimate_interests,
                $self->{num_custom_purposes}
            ),
        },
    };
}

sub _format_json_subsection {
    my ( $self, $data, $max ) = @_;

    my ( $false, $true ) = @{ $self->{options}->{json}->{boolean_values} };

    if ( !!$self->{options}->{json}->{compact} ) {
        return [
            grep { $data->{$_} } 1 .. $max,
        ];
    }

    my $verbose = !!$self->{options}->{json}->{verbose};

    return $data if $verbose;

    return { map { $_ => $true } grep { $data->{$_} } keys %{$data} };
}

sub _safe_is_purpose_consent_allowed {
    my ( $self, $id ) = @_;
    return
      scalar(
        is_set( $self->{data}, OFFSETS->{PURPOSE_CONSENT_ALLOWED} + $id - 1 )
      );
}

sub _safe_is_purpose_legitimate_interest_allowed {
    my ( $self, $id ) = @_;

    return
      scalar(
        is_set( $self->{data}, OFFSETS->{PURPOSE_LIT_ALLOWED} + $id - 1 ) );
}

sub _safe_is_custom_purpose_consent_allowed {
    my ( $self, $id ) = @_;
    return
      scalar(
        is_set( $self->{data}, OFFSETS->{CUSTOM_PURPOSES_CONSENT} + $id - 1 )
      );
}

sub _safe_is_custom_purpose_legitimate_interest_allowed {
    my ( $self, $id ) = @_;

    return
      scalar(
        is_set( $self->{data}, $self->{custom_purpose_lit_offset} + $id - 1 )
      );
}

1;
__END__

=head1 NAME

GDPR::IAB::TCFv2::PublisherTC - Transparency & Consent String version 2 publisher tc

=head1 SYNOPSIS

    my $publisher_tc = GDPR::IAB::TCFv2::PublisherTC->Parse(
        data         => $publisher_tc_data,
        data_size    => length($publisher_tc_data),
        options      => { json => ... },
    );

    say num_custom_purposes;

    say "there is publisher restriction on purpose id 1, type 0 on vendor 284"
        if $publisher_tc->check_restriction(1, 0, 284);

=head1 CONSTRUCTOR

Constructor C<Parse> receives an hash of 3 parameters: 

=over

=item *

Key C<data> is the binary data

=item *

Key C<data_size> is the original binary data size

=item *

Key C<options> is the L<GDPR::IAB::TCFv2> options (includes the C<json> field to modify the L</TO_JSON> method output.

=back

=head1 METHODS

=head2 num_custom_purposes

Custom purpose IDs are numbered 1 to NumberCustomPurposes. Custom purposes will be defined by the publisher and displayed to a user in a CMP user interface.

If the publisher does not use any Custom Purposes, this method returns 0.

=head2 is_purpose_consent_allowed 

The user's consent value for each Purpose established on the legal basis of consent, for the publisher.

=head2 is_purpose_legitimate_interest_allowed

The Purposes transparency requir'ements are met for each Purpose established on the legal basis of legitimate interest and the user has not exercised their "Right to Object" to that Purpose.

By default or if the user has exercised their "Right to Object to a Purpose", the corresponding bit for that purpose is set to 0

=head2 is_custom_purpose_consent_allowed 

The consent value for each custom purpose id

=head2 is_custom_purpose_legitimate_interest_allowed 

The legitimate Interest disclosure establishment value for each custom purpose id

=head2 TO_JSON

Returns a hashref with the following format:

    {
        consents => ...,
        legitimate_interests => ...,
        custom_purposes => {
            consents => ...,
            legitimate_interests => ...,
        },
        restrictions => {
            '[purpose id]' => {
                # 0 - Not Allowed
                # 1 - Require Consent
                # 2 - Require Legitimate Interest
                '[vendor id]' => 1,
            },
        }
    }

Example, by parsing the consent C<COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA.argAC0gAAAAAAAAAAAA> we can generate this compact hashref.

    {
      "consents" : [
         2,
         4,
         6,
         8,
         9,
         10
      ],
      "legitimate_interests" : [
         2,
         4,
         5,
         7,
         10
      ],
      "custom_purpose" : {
         "consents" : [],
         "legitimate_interests" : []
      },
      "restrictions" : {
         "7" : {
            "32" : 1
         }
      }
    }

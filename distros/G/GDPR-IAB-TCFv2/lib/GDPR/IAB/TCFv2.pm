package GDPR::IAB::TCFv2;

use strict;
use warnings;
use integer;
use bytes;

use MIME::Base64 qw<decode_base64>;
use Carp         qw<croak>;

use GDPR::IAB::TCFv2::BitField;
use GDPR::IAB::TCFv2::BitUtils qw<is_set
  get_uint2
  get_uint6
  get_uint12
  get_uint16
  get_uint36
  get_char6_pair
>;
use GDPR::IAB::TCFv2::PublisherRestrictions;
use GDPR::IAB::TCFv2::RangeSection;

our $VERSION = "0.07";

use constant CONSENT_STRING_TCF2_SEPARATOR => '.';
use constant CONSENT_STRING_TCF2_PREFIX    => 'C';
use constant MIN_BYTE_SIZE                 => 29;
use constant MIN_BIT_SIZE                  => 8 * MIN_BYTE_SIZE;
use constant TCF_VERSION                   => 2;
use constant ASSUMED_MAX_VENDOR_ID         => 0x7FFF;   # 32767 or (1 << 15) -1

INIT {
    if ( my $native_decode_base64url = MIME::Base64->can("decode_base64url") )
    {
        no warnings q<redefine>;

        *_decode_base64url = $native_decode_base64url;
    }
}

# ABSTRACT: gdpr iab tcf v2 consent string parser

sub Parse {
    my ( $klass, $tc_string ) = @_;

    croak 'missing gdpr consent string' unless $tc_string;

    my $core_tc_string = _get_core_tc_string($tc_string);

    my $data      = unpack 'B*', _validate_and_decode_base64($core_tc_string);
    my $data_size = length($data);

    croak "vendor consent strings are at least @{[ MIN_BYTE_SIZE ]} bytes long"
      if $data_size < MIN_BIT_SIZE;

    my $self = {
        data                           => $data,
        tc_string                      => $tc_string,
        vendor_consents                => undef,
        legitimate_interest_max_vendor => undef,
        vendor_legitimate_interests    => undef,
        publisher_restrictions         => undef,
    };

    bless $self, $klass;

    croak 'consent string is not tcf version 2'
      unless $self->version == TCF_VERSION;

    croak 'invalid vendor list version' unless $self->vendor_list_version;

    # parse consent

    my $legitimate_interest_start = $self->_parse_vendor_consents();

    # parse legitimate interest

    my $pub_restrict_start =
      $self->_parse_vendor_legitimate_interests($legitimate_interest_start);

    # parse publisher restrictions from section core string

    $self->_parse_publisher_restrictions($pub_restrict_start);

    # parse section disclosed vendors if available

    # parse section publisher_tc if available

    return $self;
}

sub version {
    my $self = shift;

    return get_uint6( $self->{data}, 0 );
}

sub created {
    my $self = shift;

    my ( $seconds, $nanoseconds ) = $self->_get_epoch(6);

    return wantarray ? ( $seconds, $nanoseconds ) : $seconds;
}

sub last_updated {
    my $self = shift;

    my ( $seconds, $nanoseconds ) = $self->_get_epoch(42);

    return wantarray ? ( $seconds, $nanoseconds ) : $seconds;
}

sub _get_epoch {
    my ( $self, $offset ) = @_;

    my $deciseconds = get_uint36( $self->{data}, $offset );

    return (
        ( $deciseconds / 10 ),
        ( ( $deciseconds % 10 ) * 100_000_000 ),
    );
}

sub cmp_id {
    my $self = shift;

    return get_uint12( $self->{data}, 78 );
}

sub cmp_version {
    my $self = shift;

    return get_uint12( $self->{data}, 90 );
}

sub consent_screen {
    my $self = shift;

    return get_uint6( $self->{data}, 102 );
}

sub consent_language {
    my $self = shift;

    return get_char6_pair( $self->{data}, 108 );
}

sub vendor_list_version {
    my $self = shift;

    return get_uint12( $self->{data}, 120 );
}

sub policy_version {
    my $self = shift;

    return get_uint6( $self->{data}, 132 );
}

sub is_service_specific {
    my $self = shift;

    return is_set( $self->{data}, 138 );
}

sub use_non_standard_stacks {
    my $self = shift;

    return is_set( $self->{data}, 139 );
}

sub is_special_feature_opt_in {
    my ( $self, $id ) = @_;

    croak "invalid special feature id $id: must be between 1 and 12"
      if $id < 1 || $id > 12;

    return is_set( $self->{data}, 140 + $id - 1 );
}

sub is_purpose_consent_allowed {
    my ( $self, $id ) = @_;

    croak "invalid purpose id $id: must be between 1 and 24"
      if $id < 1 || $id > 24;

    return is_set( $self->{data}, 152 + $id - 1 );
}

sub is_purpose_legitimate_interest_allowed {
    my ( $self, $id ) = @_;

    croak "invalid purpose id $id: must be between 1 and 24"
      if $id < 1 || $id > 24;

    return is_set( $self->{data}, 176 + $id - 1 );
}

sub purpose_one_treatment {
    my $self = shift;

    return is_set( $self->{data}, 200 );
}

sub publisher_country_code {
    my $self = shift;

    return get_char6_pair( $self->{data}, 201 );
}

sub max_vendor_id_consent {
    my $self = shift;

    return get_uint16( $self->{data}, 213 );
}

sub max_vendor_id_legitimate_interest {
    my $self = shift;

    return $self->{legitimate_interest_max_vendor};
}

sub vendor_consent {
    my ( $self, $id ) = @_;

    return $self->{vendor_consents}->contains($id);
}

sub vendor_legitimate_interest {
    my ( $self, $id ) = @_;

    return $self->{vendor_legitimate_interests}->contains($id);
}

sub check_publisher_restriction {
    my ( $self, $purpose_id, $restrict_type, $vendor ) = @_;

    return $self->{publisher_restrictions}
      ->check_publisher_restriction( $purpose_id, $restrict_type, $vendor );
}

sub _parse_vendor_consents {
    my $self = shift;

    my ( $vendor_consents, $legitimate_interest_start );

    if ( $self->_is_vendor_consent_range_encoding ) {
        ( $vendor_consents, $legitimate_interest_start ) =
          $self->_parse_range_section( $self->max_vendor_id_consent, 230 );
    }
    else {
        ( $vendor_consents, $legitimate_interest_start ) =
          $self->_parse_bitfield( $self->max_vendor_id_consent, 230 );
    }

    $self->{vendor_consents} = $vendor_consents;

    return $legitimate_interest_start;
}

sub _parse_vendor_legitimate_interests {
    my ( $self, $legitimate_interest_start ) = @_;

    my $legitimate_interest_max_vendor =
      get_uint16( $self->{data}, $legitimate_interest_start );

    $self->{legitimate_interest_max_vendor} = $legitimate_interest_max_vendor;

    my $data_size = length( $self->{data} );
    croak
      "invalid consent data: no legitimate interest start position (got $legitimate_interest_start + 16 but $data_size)"
      if $legitimate_interest_start + 16 > $data_size;

    my $is_vendor_legitimate_interest_range =
      is_set( $self->{data}, $legitimate_interest_start + 16 );

    my ( $vendor_legitimate_interests, $pub_restrict_start );

    if ($is_vendor_legitimate_interest_range) {
        ( $vendor_legitimate_interests, $pub_restrict_start ) =
          $self->_parse_range_section(
            $self->max_vendor_id_legitimate_interest,
            $legitimate_interest_start + 17
          );
    }
    else {
        ( $vendor_legitimate_interests, $pub_restrict_start ) =
          $self->_parse_bitfield(
            $self->max_vendor_id_legitimate_interest,
            $legitimate_interest_start + 17
          );
    }

    $self->{vendor_legitimate_interests} = $vendor_legitimate_interests;

    return $pub_restrict_start;
}

sub _parse_publisher_restrictions {
    my ( $self, $pub_restrict_start ) = @_;

    my $num_restrictions = get_uint12( $self->{data}, $pub_restrict_start );

    my %restrictions;

    my $current_offset = $pub_restrict_start + 12;

    for ( 1 .. $num_restrictions ) {
        my $purpose_id = get_uint6( $self->{data}, $current_offset );
        $current_offset += 6;
        my $restriction_type = get_uint2( $self->{data}, $current_offset );
        $current_offset += 2;

        my ( $vendor_restrictions, $next_offset ) =
          $self->_parse_range_section(
            ASSUMED_MAX_VENDOR_ID,
            $current_offset
          );

        $restrictions{$purpose_id} ||= {};

        $restrictions{$purpose_id}->{$restriction_type} = $vendor_restrictions;

        $current_offset = $next_offset;
    }

    my $publisher_restrictions = GDPR::IAB::TCFv2::PublisherRestrictions->new(
        restrictions => \%restrictions,
    );

    $self->{publisher_restrictions} = $publisher_restrictions;

    return $current_offset;
}

sub _get_core_tc_string {
    my $tc_string = shift;

    my $pos = index( $tc_string, CONSENT_STRING_TCF2_SEPARATOR );

    return $tc_string if $pos < 0;

    return substr( $tc_string, 0, $pos );
}

sub _validate_and_decode_base64 {
    my $s = shift;

    # see: https://www.perlmonks.org/?node_id=775820
    croak "invalid base64 format" unless $s =~ m{
        ^
        (?: [A-Za-z0-9-_]{4} )*
        (?:
            [A-Za-z0-9-_]{2} [AEIMQUYcgkosw048] =?
        |
            [A-Za-z0-9-_] [AQgw] (?:==)?
        )?
        \z
    }x;

    return _decode_base64url($s);
}

sub _decode_base64url {
    my $s = shift;
    $s =~ tr[-_][+/];
    $s .= '=' while length($s) % 4;
    return decode_base64($s);
}

sub _is_vendor_consent_range_encoding {
    my $self = shift;

    return is_set( $self->{data}, 229 );
}

sub _parse_range_section {
    my ( $self, $vendor_bits_required, $start_bit ) = @_;

    my $range_section = GDPR::IAB::TCFv2::RangeSection->new(
        data                 => $self->{data},
        start_bit            => $start_bit,
        vendor_bits_required => $vendor_bits_required,
    );

    return ( $range_section, $range_section->current_offset );
}

sub _parse_bitfield {
    my ( $self, $vendor_bits_required, $start_bit ) = @_;

    my $bitfield = GDPR::IAB::TCFv2::BitField->new(
        data                 => $self->{data},
        start_bit            => $start_bit,
        vendor_bits_required => $vendor_bits_required,
    );

    return ( $bitfield, $start_bit + $vendor_bits_required );
}

sub looksLikeIsConsentVersion2 {
    my ($gdpr_consent_string) = @_;

    return unless defined $gdpr_consent_string;

    return rindex( $gdpr_consent_string, CONSENT_STRING_TCF2_PREFIX, 0 ) == 0;
}

1;
__END__

=pod

=encoding utf8

=for html <a href="https://cpants.cpanauthors.org/dist/GDPR-IAB-TCFv2"><img src="https://cpants.cpanauthors.org/dist/GDPR-IAB-TCFv2.svg" alt='Kwalitee'/></a>

=for html <a href="https://github.com/peczenyj/GDPR-IAB-TCFv2/actions/workflows/linux.yml"><img src="https://github.com/peczenyj/GDPR-IAB-TCFv2/actions/workflows/linux.yml/badge.svg" alt='tests"/></a>

=for html <a href='https://ci.appveyor.com/project/peczenyj/gdpr-iab-tcfv2'><img src='https://ci.appveyor.com/api/projects/status/p2e2478cufcdqanl?svg=true' alt='appveyor'/></a>

=for html <a href='https://coveralls.io/github/peczenyj/GDPR-IAB-TCFv2?branch=main'><img src='https://coveralls.io/repos/github/peczenyj/GDPR-IAB-TCFv2/badge.svg?branch=main' alt='Coverage Status' /></a>

=for html <a href="https://github.com/peczenyj/GDPR-IAB-TCFv2/blob/master/LICENSE"><img src="https://img.shields.io/cpan/l/GDPR-IAB-TCFv2.svg" alt='license'/></a>

=for html <a href="https://metacpan.org/dist/GDPR-IAB-TCFv2"><img src="https://img.shields.io/cpan/v/GDPR-IAB-TCFv2.svg" alt='cpan'/></A>

=head1 NAME

GDPR::IAB::TCFv2 - Transparency & Consent String version 2 parser 

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

The purpose of this package is to parse Transparency & Consent String (TC String) as defined by IAB version 2.

    use strict;
    use warnings;
    
    use GDPR::IAB::TCFv2;
    use GDPR::IAB::TCFv2::Constants::Purpose qw<:all>;
    use GDPR::IAB::TCFv2::Constants::SpecialFeature qw<:all>;
    use GDPR::IAB::TCFv2::Constants::RestrictionType qw<:all>;

    my $consent = GDPR::IAB::TCFv2->Parse(
        'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA.argAC0gAAAAAAAAAAAA'
    );

    use feature qw<say>;

    say $consent->version;             # 2
    say $consent->created;             # epoch 1228644257 or 07/12/2008
    say $consent->last_updated;        # epoch 1326215413 or 10/01/2012
    say $consent->cmp_id;              # 21 - Traffective GmbH 
    say $consent->cmp_version;         # 7
    say $consent->consent_screen;      # 2
    say $consent->consent_language;    # "EN"
    say $consent->vendor_list_version; # 23

    use List::MoreUtils qw<all>;

    say "find consent for purpose ids 1, 3, 9 and 10" if all {
        $consent->is_purpose_consent_allowed($_)
    } ( # constants exported by GDPR::IAB::TCFv2::Constants::Purpose
        InfoStorageAccess,       #  1
        PersonalizationProfile,  #  3
        MarketResearch,          #  9
        DevelopImprove,          # 10
    );

    say "find consent for vendor id 284 (Weborama)" if $consent->vendor_consent(284);

    # Geolocation exported by GDPR::IAB::TCFv2::Constants::SpecialFeature
    say "user is opt in for special feature 'Geolocation (id 1)'" 
        if $consent->is_special_feature_opt_in(Geolocation);

    # NotAllowed exported by GDPR::IAB::TCFv2::Constants::RestrictionType
    say "publisher restriction for purpose Info Storage Access (1), restriction type NotAllowed (0) for weborama (284)" 
        if $consent->check_publisher_restriction(InfoStorageAccess, NotAllowed, 284);

=head1 ACRONYMS

L<GDPR|https://gdpr-info.eu/>: General Data Protection Regulation

L<IAB|https://iabeurope.eu/about-us/>: Interactive Advertising Bureau 

L<TCF|https://iabeurope.eu/transparency-consent-framework/>: The Transparency & Consent Framework

=head1 CONSTRUCTOR

=head2 Parse

The Parse method will decode and validate a base64 encoded version of the tcf v2 string.

Will return a C<GDPR::IAB::TCFv2> immutable object that allow easy access to different properties.

Will die if can't decode the string.

    use GDPR::IAB::TCFv2;

    my $consent = GDPR::IAB::TCFv2->Parse(
        'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA.argAC0gAAAAAAAAAAAA'
    );

=head1 METHODS

=head2 version

Version number of the encoding format. The value is 2 for this format.

=head2 created

Epoch time format when TC String was created in numeric format. You can easily parse with L<DateTime> if needed.

On scalar context it returns epoch in seconds. On list context it returns epoch in seconds and nanoseconds.

    use GDPR::IAB::TCFv2;
    use Test::More tests => 3;

    my $consent = GDPR::IAB::TCFv2->Parse(
        'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA.argAC0gAAAAAAAAAAAA'
    );

    is $consent->created, 1228644257,
      'should return the creation epoch 07/12/2008';

    my ( $seconds, $nanoseconds ) = $consent->created;
    is $seconds, 1228644257,
        'should return the creation epoch 07/12/2008 on list context';
    is $nanoseconds, 700000000,
        'should return the 700000000 nanoseconds of epoch on list context';
    
=head2 last_updated

Epoch time format when TC String was last updated in numeric format. You can easily parse with L<DateTime> if needed.

On scalar context it returns epoch in seconds. On list context it returns epoch in seconds and nanoseconds, like the C<created>

=head2 cmp_id

Consent Management Platform ID that last updated the TC String. Is a unique ID will be assigned to each Consent Management Platform.

=head2 cmp_version

Consent Management Platform version of the CMP that last updated this TC String.
Each change to a CMP should increment their internally assigned version number as a record of which version the user gave consent and transparency was established.

=head2 consent_screen

CMP Screen number at which consent was given for a user with the CMP that last updated this TC String.
The number is a CMP internal designation and is CmpVersion specific. The number is used for identifying on which screen a user gave consent as a record.

=head2 consent_language

Two-letter L<ISO 639-1|https://en.wikipedia.org/wiki/ISO_639-1> language code in which the CMP UI was presented.

=head2 vendor_list_version

Number corresponds to L<GVL|https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md#the-global-vendor-list> vendorListVersion.
Version of the GVL used to create this TC String.

=head2 policy_version

Version of policy used within L<GVL|https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md#the-global-vendor-list>.

From the corresponding field in the GVL that was used for obtaining consent.

=head2 is_service_specific

This field must always have the value of 1. When a Vendor encounters a TC String with C<is_service_specific=0> then it is considered invalid.

=head2 use_non_standard_stacks

If true, CMP used non-IAB standard texts during consent gathering.

Setting this to 1 signals to Vendors that a private CMP has modified standard Stack descriptions and/or their translations and/or that a CMP has modified or supplemented standard Illustrations and/or their translations as allowed by the policy..

=head2 is_special_feature_opt_in

If true means Opt in.

The TCF L<Policies|https://iabeurope.eu/iab-europe-transparency-consent-framework-policies/> designates certain Features as "special" which means a CMP must afford the user a means to opt in to their use. These "Special Features" are published and numerically identified in the L<Global Vendor List separately|https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md#the-global-vendor-list> from normal Features.

See also: L<GDPR::IAB::TCFv2::Constants::SpecialFeature>.

=head2 is_purpose_consent_allowed

If true means Consent.

The user's consent value for each Purpose established on the legal basis of consent.

    my $ok = $instance->is_purpose_consent_allowed(1);

See also: L<GDPR::IAB::TCFv2::Constants::Purpose>.

=head2 is_purpose_legitimate_interest_allowed

The user's consent value for each Purpose established on the legal basis of legitimate interest.

    my $ok = $instance->is_purpose_legitimate_interest_allowed(1);

See also: L<GDPR::IAB::TCFv2::Constants::Purpose>.

=head2 purpose_one_treatment

CMPs can use the PublisherCC field to indicate the legal jurisdiction the publisher is under to help vendors determine whether the vendor needs consent for Purpose 1.

Returns true if Purpose 1 was NOT disclosed at all.

Returns false if Purpose 1 was disclosed commonly as consent as expected by the L<Policies|https://iabeurope.eu/iab-europe-transparency-consent-framework-policies/>.

=head2 publisher_country_code

Two-letter L<ISO 639-1|https://en.wikipedia.org/wiki/ISO_639-1> language code of the country that determines legislation of reference. 
Commonly, this corresponds to the country in which the publisher's business entity is established.

=head2 max_vendor_id_consent

The maximum Vendor ID that is represented in the following bit field or range encoding.

Because this section can be a variable length, this indicates the last ID of the section so that a decoder will know when it has reached the end.

=head2 vendor_consent

If true, vendor has consent.

The consent value for each Vendor ID.

    my $ok = $instance->vendor_consent(284); # if true, consent ok for Weborama (vendor id 284).

=head2 max_vendor_id_legitimate_interest

The maximum Vendor ID that is represented in the following bit field or range encoding.

Because this section can be a variable length, this indicates the last ID of the section so that a decoder will know when it has reached the end.

=head2 vendor_legitimate_interest

If true, legitimate interest established.

The legitimate interest value for each Vendor ID

    my $ok = $instance->vendor_legitimate_interest(284); # if true, legitimate interest established for Weborama (vendor id 284).

=head2 check_publisher_restriction

It true, there is a publisher restriction of certain type, for a given purpose id, for a given vendor id:

    # return true if there is publisher restriction to vendor 284 regarding purpose id 1 
    # with restriction type 0 'Purpose Flatly Not Allowed by Publisher'
    my $ok = $instance->check_publisher_restriction(1, 0, 204);

Version 2.0 of the Framework introduced the ability for publishers to signal restrictions on how vendors may process personal data. Restrictions can be of two types:

=over

=item *

Purposes. Restrict the purposes for which personal data is processed by a vendor.

=item *

Legal basis. Specify the legal basis upon which a publisher requires a vendor to operate where a vendor has signaled flexibility on legal basis in the GVL.

=back

Publisher restrictions are custom requirements specified by a publisher. In order for vendors to determine if processing is permissible at all for a specific purpose or which legal basis is applicable (in case they signaled flexibility in the GVL) restrictions must be respected.

=over

=item 1
Vendors must always respect a restriction signal that disallows them the processing for a specific purpose regardless of whether or not they have declared that purpose to be “flexible”.
=item 2

Vendors that declared a purpose with a default legal basis (consent or legitimate interest respectively) but also declared this purpose as flexible must respect a legal basis restriction if present. That means for example in case they declared a purpose as legitimate interest but also declared that purpose as flexible and there is a legal basis restriction to require consent, they must then check for the consent signal and must not apply the legitimate interest signal.

=back

For the avoidance of doubt:

In case a vendor has declared flexibility for a purpose and there is no legal basis restriction signal it must always apply the default legal basis under which the purpose was registered aside from being registered as flexible. That means if a vendor declared a purpose as legitimate interest and also declared that purpose as flexible it may not apply a "consent" signal without a legal basis restriction signal to require consent.

=head1 FUNCTIONS

=head2 looksLikeIsConsentVersion2

Will check if a given tc string starts with a literal C<C>.

=head1 SEE ALSO

The original documentation of the L<TCF v2 from IAB documentation|https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md>.

=head1 AUTHOR

Tiago Peczenyj L<mailto:tiago.peczenyj+gdpr-iab-tcfv2@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/peczenyj/GDPR-IAB-TCFv2/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2023 Tiago Peczenyj

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

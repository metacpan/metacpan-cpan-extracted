package GDPR::IAB::TCFv2::Validator::Reason 0.530;
use v5.12;
use warnings;

require Exporter;
use parent qw<Exporter>;


use constant {

  # Successful validation: no failure to report.
  ReasonNone => 0,

  # The TCF string is missing the mandatory disclosed vendors segment
  # (TCF v2.2+ requirement).
  ReasonMissingDisclosedVendors => 1,

  # The configured vendor ID is not present in the disclosed vendors
  # segment.
  ReasonVendorNotDisclosed => 2,

  # The vendor is not allowed globally (neither consent nor legitimate
  # interest is granted for any purpose).
  ReasonVendorNotAllowed => 3,

  # A required purpose is not allowed for the vendor.
  ReasonPurposeNotAllowed => 4,

  # A publisher restriction of type 0 (Not Allowed) is present for a
  # required purpose.
  ReasonPublisherRestrictionNotAllowed => 5,

  # A publisher restriction of type 1 (Requires Consent) is present
  # for a purpose configured under the legitimate-interest legal basis.
  ReasonPublisherRestrictionRequireConsent => 6,

  # A publisher restriction of type 2 (Requires Legitimate Interest) is
  # present for a purpose configured under the consent legal basis.
  ReasonPublisherRestrictionRequireLegitimateInterest => 7,

  # The vendor is not allowed for a specific purpose under the consent
  # legal basis (vendor consent flag and/or purpose consent flag missing).
  ReasonVendorNotAllowedConsent => 8,

  # The vendor is not allowed for a specific purpose under the legitimate
  # interest legal basis (vendor LI flag and/or purpose LI flag missing).
  ReasonVendorNotAllowedLegitimateInterest => 9,

  # The TCF spec forbids the legitimate-interest legal basis for this
  # purpose: Purpose 1 always; Purposes 3-6 on TcfPolicyVersion >= 4.
  ReasonLegitimateInterestNotPermittedForPurpose => 10,

  # The consent string's TcfPolicyVersion is below the validator's
  # configured minimum.
  ReasonPolicyVersionTooLow => 11,

  # The consent string could not be decoded (malformed, empty, or
  # unsupported version). Only emitted when explicitly requested.
  ReasonDecodeError => 12,

  # The consent string's CMP ID is not recognized as a valid (active,
  # non-deleted) entry in the configured CMP registry.
  ReasonInvalidCMP => 13,

  # The CMP id is recognized but has been retired (deletedDate in the past).
  ReasonCMPDeleted => 14,

  # The CMP id is unknown to the registry.
  ReasonCMPUnknown => 15,
};

use constant ReasonDescription => {
  ReasonNone                                          => "no failure",
  ReasonMissingDisclosedVendors                       => "missing disclosed vendors",
  ReasonVendorNotDisclosed                            => "vendor not disclosed",
  ReasonVendorNotAllowed                              => "vendor not allowed",
  ReasonPurposeNotAllowed                             => "purpose not allowed",
  ReasonPublisherRestrictionNotAllowed                => "publisher restriction: not allowed",
  ReasonPublisherRestrictionRequireConsent            => "publisher restriction: requires consent",
  ReasonPublisherRestrictionRequireLegitimateInterest => "publisher restriction: requires legitimate interest",
  ReasonVendorNotAllowedConsent                       => "vendor not allowed for purpose (consent)",
  ReasonVendorNotAllowedLegitimateInterest            => "vendor not allowed for purpose (legitimate interest)",
  ReasonLegitimateInterestNotPermittedForPurpose      => "legitimate interest not permitted for purpose",
  ReasonPolicyVersionTooLow                           => "tcf policy version too low",
  ReasonDecodeError                                   => "decode error",
  ReasonInvalidCMP                                    => "invalid cmp id",
  ReasonCMPDeleted                                    => "deleted cmp id",
  ReasonCMPUnknown                                    => "unknown cmp id",
};

# Lazily built reverse map: integer code -> human-readable string.
my %_CODE_TO_STRING;

sub reason_string {
  my ($code) = @_;

  return "unknown validation failure" unless defined $code;

  unless (%_CODE_TO_STRING) {
    my $desc = ReasonDescription;
    for my $name (keys %{$desc}) {
      my $value = __PACKAGE__->can($name)->();
      $_CODE_TO_STRING{$value} = $desc->{$name};
    }
  }

  my $string = $_CODE_TO_STRING{$code};
  return defined($string) ? $string : "unknown validation failure";
}

our @EXPORT_OK = qw<
  ReasonNone
  ReasonMissingDisclosedVendors
  ReasonVendorNotDisclosed
  ReasonVendorNotAllowed
  ReasonPurposeNotAllowed
  ReasonPublisherRestrictionNotAllowed
  ReasonPublisherRestrictionRequireConsent
  ReasonPublisherRestrictionRequireLegitimateInterest
  ReasonVendorNotAllowedConsent
  ReasonVendorNotAllowedLegitimateInterest
  ReasonLegitimateInterestNotPermittedForPurpose
  ReasonPolicyVersionTooLow
  ReasonDecodeError
  ReasonInvalidCMP
  ReasonCMPDeleted
  ReasonCMPUnknown
  ReasonDescription
  reason_string
>;

our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;

__END__

=encoding utf8

=head1 NAME

GDPR::IAB::TCFv2::Validator::Reason - machine-readable validation-failure codes

=head1 SYNOPSIS

    use warnings;

    use GDPR::IAB::TCFv2::Validator::Reason qw<:all>;

    use feature 'say';

    say "Code is ", ReasonVendorNotDisclosed,
        ", and it means ", reason_string(ReasonVendorNotDisclosed);
    # Output:
    # Code is 2, and it means vendor not disclosed

    # Lookup by name via the description hashref (auto-quoted bareword).
    say ReasonDescription->{ReasonPublisherRestrictionNotAllowed};
    # Output:
    # publisher restriction: not allowed

=head1 DESCRIPTION

Stable, integer-valued reason codes that describe why
L<GDPR::IAB::TCFv2::Validator/validate> or
L<GDPR::IAB::TCFv2::Validator/validate_all> rejected a
TCF consent string.
 The set mirrors the C<Reason> enum from the Go
C<lib-gdpr/validator> package so cross-language tooling can share a
single vocabulary.

Each code is also accompanied by a short human-readable string available
via L</reason_string> (lookup by integer) or L</ReasonDescription>
(lookup by constant name).

=head1 CONSTANTS

All constants are non-negative integers. The values are stable: new codes
are appended; existing codes never change.

=head2 ReasonNone

Code 0. Successful validation; no failure to report.

=head2 ReasonMissingDisclosedVendors

Code 1. The TC string is missing the mandatory disclosed vendors segment
(TCF v2.2+ requirement under policy version >= 5).

=head2 ReasonVendorNotDisclosed

Code 2. The configured vendor ID is not present in the disclosed vendors
segment.

=head2 ReasonVendorNotAllowed

Code 3. The vendor is not allowed globally: neither vendor consent nor
vendor legitimate interest is granted for any purpose.

=head2 ReasonPurposeNotAllowed

Code 4. A required purpose has neither its consent flag nor its
legitimate-interest flag set.

=head2 ReasonPublisherRestrictionNotAllowed

Code 5. A publisher restriction of type 0 (Not Allowed) is present for
a required purpose. Always rejects.

=head2 ReasonPublisherRestrictionRequireConsent

Code 6. A publisher restriction of type 1 (Requires Consent) is present
for a purpose configured under the legitimate-interest legal basis.

=head2 ReasonPublisherRestrictionRequireLegitimateInterest

Code 7. A publisher restriction of type 2 (Requires Legitimate Interest)
is present for a purpose configured under the consent legal basis.

=head2 ReasonVendorNotAllowedConsent

Code 8. The vendor is not allowed for a specific purpose under the
consent legal basis (vendor consent flag and/or purpose consent flag is
missing).

=head2 ReasonVendorNotAllowedLegitimateInterest

Code 9. The vendor is not allowed for a specific purpose under the
legitimate-interest legal basis (vendor LI flag and/or purpose LI flag
is missing).

=head2 ReasonLegitimateInterestNotPermittedForPurpose

Code 10. The TCF spec forbids the legitimate-interest legal basis for
this purpose, regardless of the vendor's signal: Purpose 1 always, and
Purposes 3-6 on TcfPolicyVersion >= 4 (TCF v2.2+).

=head2 ReasonPolicyVersionTooLow

Code 11. The consent string's TcfPolicyVersion is below the validator's
configured C<min_tcf_policy_version>.

=head2 ReasonDecodeError

Code 12. The consent string could not be decoded (malformed, empty, or
unsupported version). Only emitted when the validator is configured to
report decode errors as structured failures rather than via C<croak>.

=head2 ReasonInvalidCMP

Code 13. The consent string's CMP ID is not recognized as a valid
(active, non-deleted) entry in the configured CMP registry. The
C<CMPValidator> rule today returns a single boolean; a future
refinement may add C<ReasonCMPDeleted> / C<ReasonCMPUnknown> to
distinguish lifecycle states (the codes are reserved for that work).

=head2 ReasonDescription

Hashref mapping each constant name (C<"ReasonNone">, C<"ReasonVendorNotAllowed">,
...) to its human-readable string. Useful with auto-quoted bareword
subscripts:

    my $msg = ReasonDescription->{ReasonVendorNotAllowed};

=head1 FUNCTIONS

=head2 reason_string

    my $msg = reason_string($code);

Returns the human-readable description for an integer reason code.
Returns C<"unknown validation failure"> for unknown or undefined codes.

=head1 SEE ALSO

L<GDPR::IAB::TCFv2::Validator>, L<GDPR::IAB::TCFv2::Validator::Result>.

=cut

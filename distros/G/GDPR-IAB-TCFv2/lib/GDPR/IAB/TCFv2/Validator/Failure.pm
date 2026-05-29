package GDPR::IAB::TCFv2::Validator::Failure 0.530;

use v5.12;
use warnings;

use overload
  '""'     => sub { $_[0]->{message} },
  fallback => 1;

sub new {
  my ($klass, %args) = @_;

  my $self = {
    code             => defined $args{code}    ? $args{code}    : 0,
    message          => defined $args{message} ? $args{message} : '',
    purpose_id       => $args{purpose_id},
    vendor_id        => $args{vendor_id},
    restriction_type => $args{restriction_type},
    cmp_id           => $args{cmp_id},
  };

  return bless $self, $klass;
}

sub code             { $_[0]->{code} }
sub message          { $_[0]->{message} }
sub purpose_id       { $_[0]->{purpose_id} }
sub vendor_id        { $_[0]->{vendor_id} }
sub restriction_type { $_[0]->{restriction_type} }
sub cmp_id           { $_[0]->{cmp_id} }

1;

__END__

=encoding utf8

=head1 NAME

GDPR::IAB::TCFv2::Validator::Failure - structured failure record from the Validator

=head1 SYNOPSIS

    use GDPR::IAB::TCFv2::Validator::Reason qw<:all>;

    my ($validator, $tc_string) = ('...', '...');
    my $result = $validator->validate($tc_string);

    unless ($result) {
        for my $f ( $result->failures ) {
            warn sprintf "code=%d message=%s\n", $f->code, $f->message;

            if ( $f->code == ReasonVendorNotAllowedConsent ) {
                # machine-readable handling
            }
        }
    }

=head1 DESCRIPTION

A lightweight value object describing a single failure detected by
L<GDPR::IAB::TCFv2::Validator>. Each failure carries a stable integer
C<code> from L<GDPR::IAB::TCFv2::Validator::Reason> plus the
human-readable C<message> the validator emitted, and any structured
context that is relevant to the failure (purpose ID, vendor ID,
publisher restriction type, CMP ID).

This is the per-failure analogue of the Go C<lib-gdpr/validator>
C<Result> struct: code-driven, machine-actionable, but with a
ready-to-display string already attached.

C<Validator::Failure> objects are created by
L<GDPR::IAB::TCFv2::Validator> and surfaced via
L<GDPR::IAB::TCFv2::Validator::Result/failures>; users normally do not
construct them directly.

=head1 OVERLOADS

=head2 Stringification

    print "$failure";

Returns L</message>, so a Failure object drops into any context that
expects a reason string.

=head1 METHODS

=head2 code

    my $code = $failure->code;

Integer reason code from L<GDPR::IAB::TCFv2::Validator::Reason>. Use
this to switch on the failure type programmatically.

=head2 message

    my $msg = $failure->message;

Human-readable description of the failure (the same string previously
returned by L<GDPR::IAB::TCFv2::Validator::Result/reasons>).

=head2 purpose_id

    my $pid = $failure->purpose_id;

The TCF purpose ID associated with the failure, or C<undef> when the
failure is not purpose-specific (e.g. a missing-disclosed-vendors
failure or a CMP failure).

=head2 vendor_id

    my $vid = $failure->vendor_id;

The vendor ID under validation when the failure occurred, or
C<undef> when the failure is not vendor-specific.

=head2 restriction_type

    my $rt = $failure->restriction_type;

The publisher restriction type (0 = NotAllowed, 1 = RequireConsent,
2 = RequireLegitimateInterest) when the failure was caused by a
publisher restriction, or C<undef> otherwise.

=head2 cmp_id

    my $cmp = $failure->cmp_id;

The CMP ID from the consent string when the failure was caused by the
CMP-validator rule, or C<undef> otherwise.

=head1 CONSTRUCTOR

=head2 new

Internal -- C<Validator::Failure> objects are constructed by
L<GDPR::IAB::TCFv2::Validator> as it walks its rules, then surfaced
via L<GDPR::IAB::TCFv2::Validator::Result/failures>.

=head1 SEE ALSO

L<GDPR::IAB::TCFv2::Validator::Reason> for the reason-code vocabulary,
L<GDPR::IAB::TCFv2::Validator::Result> for the container type returned
by L<GDPR::IAB::TCFv2::Validator/validate>.

=cut

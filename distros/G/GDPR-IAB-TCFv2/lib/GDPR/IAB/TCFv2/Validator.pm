package GDPR::IAB::TCFv2::Validator 0.530;

use v5.12;
use warnings;

use Carp         qw<croak>;
use Scalar::Util qw<blessed>;
use GDPR::IAB::TCFv2;
use GDPR::IAB::TCFv2::Constants::RestrictionType qw<:all>;
use GDPR::IAB::TCFv2::Validator::Failure;
use GDPR::IAB::TCFv2::Validator::Reason qw<:all>;
use GDPR::IAB::TCFv2::Validator::Result;

# TCF v2.3 became mandatory on 2026-02-28T00:00:00Z. Strings created strictly
# after this instant must use policy version >= 5 and carry a disclosed-vendors
# segment. The strictly-after comparison mirrors the Go validator's
# created.After(v23Deadline) (note: the parser's is_v23 uses >= for its own
# strict-parse gate; the Validator deliberately matches Go here).
use constant TCF_V23_DEADLINE => 1772236800;


sub new {
  my ($klass, %args) = @_;

  my $consent             = $args{consent_purpose_ids}             || [];
  my $legitimate_interest = $args{legitimate_interest_purpose_ids} || [];
  my $flexible            = $args{flexible_purpose_ids}            || [];

  _check_coherence($consent, $legitimate_interest, $flexible);

  # Compute cmp_validator in scalar context so a bare `return` from the
  # coercer correctly yields undef -- a list-context call inside the
  # anonymous-hash construction below would collapse the key/value
  # pair instead.
  my $cmp_validator = _coerce_cmp_validator($args{cmp_validator});

  # A policy floor of v2.3+ (>= 5) makes the disclosed-vendors segment
  # mandatory, so verifying it is implied. Mirrors the Go validator's
  # `verifyDisclosedVendors = cfg.VerifyDisclosedVendors || cfg.MinTcfPolicyVersion >= 5`.
  my $min              = $args{min_tcf_policy_version};
  my $verify_disclosed = ($args{verify_disclosed_vendors} // 0) || (defined $min && $min >= 5 ? 1 : 0);

  my $self = {
    vendor_id                       => $args{vendor_id},
    consent_purpose_ids             => $consent,
    legitimate_interest_purpose_ids => $legitimate_interest,
    flexible_purpose_ids            => $flexible,
    _flexible_set                   => {map { $_ => 1 } @{$flexible}},
    verify_disclosed_vendors        => $verify_disclosed,
    min_tcf_policy_version          => $min,
    cmp_validator                   => $cmp_validator,
    strict_legal_basis              => exists $args{strict_legal_basis} ? $args{strict_legal_basis} : 0,
  };

  return bless $self, $klass;
}

# Accept either a CMPValidator object, a hashref of constructor args
# (auto-instantiated lazily on the first call), or undef.  Defer the
# `require` so callers who never opt into the CMP rule never pay for
# loading JSON::PP / Time::Piece.
sub _coerce_cmp_validator {
  my ($spec) = @_;

  # Bare `return` is fine -- callers always invoke this in scalar
  # context (see the explicit `my $cmp_validator = ...` in `new` and the
  # `my $cmp_validator = ...` in `_run_validation`).
  return unless defined $spec;
  return $spec if blessed($spec) && $spec->isa('GDPR::IAB::TCFv2::CMPValidator');

  croak "cmp_validator must be a GDPR::IAB::TCFv2::CMPValidator object " . "or a hashref of constructor arguments"
    unless ref($spec) eq 'HASH';

  require GDPR::IAB::TCFv2::CMPValidator;
  return GDPR::IAB::TCFv2::CMPValidator->new(%{$spec});
}

sub _check_coherence {
  my ($consent, $legitimate_interest, $flexible) = @_;

  my %consent_set = map { $_ => 1 } @{$consent};
  my %li_set      = map { $_ => 1 } @{$legitimate_interest};

  foreach my $pid (@{$consent}) {
    croak "purpose $pid cannot be in both consent_purpose_ids and legitimate_interest_purpose_ids" if $li_set{$pid};
  }

  foreach my $pid (@{$flexible}) {
    next if $consent_set{$pid} || $li_set{$pid};
    croak "flexible purpose $pid must also appear in consent_purpose_ids or legitimate_interest_purpose_ids";
  }

  return;
}

sub validate {
  my ($self, $input, %overrides) = @_;

  return $self->_run_validation($input, 1, %overrides);
}

sub validate_all {
  my ($self, $input, %overrides) = @_;

  return $self->_run_validation($input, 0, %overrides);
}

sub _run_validation {
  my ($self, $input, $stop_on_first, %overrides) = @_;

  my $tc = ref($input) eq 'GDPR::IAB::TCFv2' ? $input : GDPR::IAB::TCFv2->Parse($input);

  my $opt = $self->_resolve_options(%overrides);

  croak "missing vendor_id" unless defined $opt->{vendor_id};

  my @failures;

  $self->_check_policy_version($tc, $opt->{min_tcf_policy_version}, \@failures);
  return $self->_make_result(0, \@failures) if $stop_on_first && @failures;

  $self->_check_cmp_validator($tc, $opt->{cmp_validator}, \@failures);
  return $self->_make_result(0, \@failures) if $stop_on_first && @failures;

  $self->_check_disclosed($tc, $opt->{vendor_id}, $opt->{verify_disclosed}, $opt->{min_tcf_policy_version}, \@failures);
  return $self->_make_result(0, \@failures) if $stop_on_first && @failures;

  # Global vendor gate: a vendor with neither consent nor legitimate interest
  # at the vendor level can never satisfy any per-purpose check, so fail with
  # ReasonVendorNotAllowed and short-circuit (in both fail-fast and exhaustive
  # modes) before walking the purpose lists.
  if ($self->_check_vendor_gate($tc, $opt->{vendor_id}, \@failures)) {
    return $self->_make_result(0, \@failures);
  }

  $self->_check_consent_purposes($tc, $opt->{vendor_id}, $opt->{strict_legal_basis},
    \@failures, $stop_on_first, $opt->{consent_ids}, $opt->{flexible_set},);
  return $self->_make_result(0, \@failures) if $stop_on_first && @failures;

  $self->_check_li_purposes($tc, $opt->{vendor_id}, $opt->{strict_legal_basis},
    \@failures, $stop_on_first, $opt->{li_ids}, $opt->{flexible_set},);

  if (@failures) {
    return $self->_make_result(0, \@failures);
  }

  return $self->_make_result(1, []);
}

# Resolve each tunable from the per-call %overrides, falling back to the
# constructor value. Returns a hashref consumed by _run_validation.
#
# Per-call list overrides do NOT re-validate coherence: orphan flexible
# purposes (a pid in flexible_purpose_ids that isn't also in
# consent_purpose_ids or legitimate_interest_purpose_ids) are silently
# dropped because the rule loops only iterate over the consent/LI lists,
# so the flex flag for an orphan is unreachable. This keeps per-call
# overrides forgiving while the constructor remains strict for the static
# policy.
sub _resolve_options {
  my ($self, %overrides) = @_;

  my %opt;

  $opt{vendor_id} = exists $overrides{vendor_id} ? $overrides{vendor_id} : $self->{vendor_id};
  $opt{strict_legal_basis}
    = exists $overrides{strict_legal_basis} ? $overrides{strict_legal_basis} : $self->{strict_legal_basis};
  $opt{verify_disclosed}
    = exists $overrides{verify_disclosed_vendors}
    ? $overrides{verify_disclosed_vendors}
    : $self->{verify_disclosed_vendors};
  $opt{min_tcf_policy_version}
    = exists $overrides{min_tcf_policy_version} ? $overrides{min_tcf_policy_version} : $self->{min_tcf_policy_version};
  $opt{cmp_validator}
    = exists $overrides{cmp_validator} ? _coerce_cmp_validator($overrides{cmp_validator}) : $self->{cmp_validator};
  $opt{consent_ids}
    = exists $overrides{consent_purpose_ids} ? $overrides{consent_purpose_ids} : $self->{consent_purpose_ids};
  $opt{li_ids}
    = exists $overrides{legitimate_interest_purpose_ids}
    ? $overrides{legitimate_interest_purpose_ids}
    : $self->{legitimate_interest_purpose_ids};
  $opt{flexible_set}
    = exists $overrides{flexible_purpose_ids}
    ? {map { $_ => 1 } @{$overrides{flexible_purpose_ids}}}
    : $self->{_flexible_set};

  return \%opt;
}

sub _check_vendor_gate {
  my ($self, $tc, $vendor_id, $failures) = @_;

  return 0 if $tc->vendor_consent($vendor_id);
  return 0 if $tc->vendor_legitimate_interest($vendor_id);

  push @{$failures},
    GDPR::IAB::TCFv2::Validator::Failure->new(
    code      => ReasonVendorNotAllowed,
    message   => "vendor $vendor_id not allowed (no consent or legitimate interest)",
    vendor_id => $vendor_id,
    );

  return 1;
}

sub _check_cmp_validator {
  my ($self, $tc, $cmp_validator, $failures) = @_;

  return unless defined $cmp_validator;

  my $cmp_id = $tc->cmp_id;

  # Prefer the lifecycle-aware state() when the provider exposes it; fall back
  # to the boolean is_valid for older/custom providers.
  if ($cmp_validator->can('state')) {
    my $state = $cmp_validator->state($cmp_id);
    return if $state eq 'active';

    my $code = $state eq 'deleted' ? ReasonCMPDeleted : $state eq 'unknown' ? ReasonCMPUnknown : ReasonInvalidCMP;

    push @{$failures},
      GDPR::IAB::TCFv2::Validator::Failure->new(
      code    => $code,
      message => "CMP $cmp_id is not valid/disclosed ($state)",
      cmp_id  => $cmp_id,
      );
    return;
  }

  unless ($cmp_validator->is_valid($cmp_id)) {
    push @{$failures},
      GDPR::IAB::TCFv2::Validator::Failure->new(
      code    => ReasonInvalidCMP,
      message => "CMP $cmp_id is not valid/disclosed",
      cmp_id  => $cmp_id,
      );
  }
  return;
}

# Single policy-version gate mirroring the Go validator's
# yieldPolicyVersionFailure: the date-based v2.3 rule takes precedence, then
# the explicit floor. At most one ReasonPolicyVersionTooLow is emitted.
sub _check_policy_version {
  my ($self, $tc, $min_tcf_policy_version, $failures) = @_;

  my $actual = $tc->policy_version;

  # A TC string created strictly after the TCF v2.3 deadline must use policy
  # version >= 5, regardless of explicit configuration. Strictly-after mirrors
  # the Go validator's created.After(v23Deadline).
  if ($tc->created > TCF_V23_DEADLINE && $actual < 5) {
    push @{$failures},
      GDPR::IAB::TCFv2::Validator::Failure->new(
      code    => ReasonPolicyVersionTooLow,
      message => "post-deadline string requires policy version >= 5",
      );
    return;
  }

  if (defined $min_tcf_policy_version && $actual < $min_tcf_policy_version) {
    push @{$failures},
      GDPR::IAB::TCFv2::Validator::Failure->new(
      code    => ReasonPolicyVersionTooLow,
      message => "TC string policy version $actual is below required minimum $min_tcf_policy_version",
      );
  }
  return;
}

sub _check_disclosed {
  my ($self, $tc, $vendor_id, $verify_disclosed, $min_tcf_policy_version, $failures) = @_;

  my $has_disclosure = $tc->has_vendor_disclosure;

  # Mandatory disclosed-vendors segment. Mirrors the Go validator's
  # yieldMandatoryDisclosedVendors: it runs regardless of verify_disclosed and
  # may fire on either ground (both, when they overlap):
  #   (a) any string created on/after the v2.3 deadline;
  #   (b) a policy>=5 string under a policy>=5 floor.
  unless ($has_disclosure) {
    if ($tc->created > TCF_V23_DEADLINE) {
      push @{$failures},
        GDPR::IAB::TCFv2::Validator::Failure->new(
        code    => ReasonMissingDisclosedVendors,
        message => "post-deadline string requires disclosed vendors segment",
        );
    }

    if ($tc->policy_version >= 5 && defined $min_tcf_policy_version && $min_tcf_policy_version >= 5) {
      push @{$failures},
        GDPR::IAB::TCFv2::Validator::Failure->new(
        code      => ReasonMissingDisclosedVendors,
        message   => "missing disclosed vendors segment",
        vendor_id => $vendor_id,
        );
    }
  }

  # When the segment is present and verification is on, the vendor must appear
  # in it. An absent segment is handled by the mandatory check above, never
  # here (matching Go: verifyDisclosedVendors passes when DisclosedVendors is
  # nil).
  if ($verify_disclosed && $has_disclosure && !$tc->disclosed_vendor($vendor_id)) {
    push @{$failures},
      GDPR::IAB::TCFv2::Validator::Failure->new(
      code      => ReasonVendorNotDisclosed,
      message   => "vendor $vendor_id not disclosed",
      vendor_id => $vendor_id,
      );
  }

  return;
}

sub _check_consent_purposes {
  my ($self, $tc, $vendor_id, $strict_legal_basis, $failures, $stop_on_first, $consent_ids, $flexible_set) = @_;

  foreach my $pid (@{$consent_ids}) {
    my $is_flexible = $flexible_set->{$pid};

    # Publisher-restriction inspection runs before the parser
    # delegate so a restriction-driven failure carries the precise
    # Reason* code (and restriction_type) rather than the generic
    # vendor-not-allowed code. Skipped for flexible purposes: the
    # flex API may flip the basis based on the restriction itself,
    # so what looks like a contradiction here can still pass.
    if (!$is_flexible) {
      my $pr_failure = $self->_publisher_restriction_failure($tc, $vendor_id, $pid, 0);
      if ($pr_failure) {
        push @{$failures}, $pr_failure;
        return if $stop_on_first;
        next;
      }
    }

    my $is_allowed
      = $is_flexible
      ? $tc->is_vendor_allowed_for_flexible_purpose($vendor_id, $pid, 0, strict => $strict_legal_basis)
      : $tc->is_vendor_consent_allowed($vendor_id, $pid, strict => $strict_legal_basis);

    unless ($is_allowed) {
      push @{$failures},
        $is_flexible ? $self->_flexible_failure($tc, $vendor_id, $pid, 0) : GDPR::IAB::TCFv2::Validator::Failure->new(
        code       => ReasonVendorNotAllowedConsent,
        message    => "vendor $vendor_id not allowed for purpose $pid (consent)",
        purpose_id => $pid,
        vendor_id  => $vendor_id,
        );
      return if $stop_on_first;
    }
  }
  return;
}

sub _check_li_purposes {
  my ($self, $tc, $vendor_id, $strict_legal_basis, $failures, $stop_on_first, $li_ids, $flexible_set) = @_;

  my $policy_version = $tc->policy_version;

  foreach my $pid (@{$li_ids}) {
    my $is_flexible = $flexible_set->{$pid};

    # TCF carve-out: legitimate interest is never permitted for
    # Purpose 1, and is forbidden for Purposes 3-6 in TCF v2.2+
    # (TcfPolicyVersion >= 4). When the configured basis is LI and
    # the purpose is not flexible, this is a configuration the
    # spec cannot satisfy regardless of the vendor's signals; emit
    # the dedicated reason instead of the generic LI failure so
    # callers can distinguish "spec forbids this" from "vendor
    # missing the LI bit".
    if (!$is_flexible && _li_carve_out_applies($pid, $policy_version)) {
      push @{$failures},
        GDPR::IAB::TCFv2::Validator::Failure->new(
        code       => ReasonLegitimateInterestNotPermittedForPurpose,
        message    => "legitimate interest not permitted for purpose $pid",
        purpose_id => $pid,
        vendor_id  => $vendor_id,
        );
      return if $stop_on_first;
      next;
    }

    # Publisher-restriction inspection: same rationale as on the
    # consent path. Skipped for flexible purposes (the flex API
    # honors the restriction by flipping bases, so what looks like
    # a contradiction here can still pass).
    if (!$is_flexible) {
      my $pr_failure = $self->_publisher_restriction_failure($tc, $vendor_id, $pid, 1);
      if ($pr_failure) {
        push @{$failures}, $pr_failure;
        return if $stop_on_first;
        next;
      }
    }

    my $is_allowed
      = $is_flexible
      ? $tc->is_vendor_allowed_for_flexible_purpose($vendor_id, $pid, 1, strict => $strict_legal_basis)
      : $tc->is_vendor_legitimate_interest_allowed($vendor_id, $pid, strict => $strict_legal_basis);

    unless ($is_allowed) {
      push @{$failures},
        $is_flexible ? $self->_flexible_failure($tc, $vendor_id, $pid, 1) : GDPR::IAB::TCFv2::Validator::Failure->new(
        code       => ReasonVendorNotAllowedLegitimateInterest,
        message    => "vendor $vendor_id not allowed for purpose $pid (legitimate interest)",
        purpose_id => $pid,
        vendor_id  => $vendor_id,
        );
      return if $stop_on_first;
    }
  }
  return;
}

# Build the failure for a flexible purpose the parser rejected, mirroring the
# Go validator's runFlexibleCheck reason selection. NotAllowed wins outright;
# otherwise the effective legal basis decides the generic reason -- a spec
# carve-out forces consent, then a Require* publisher restriction overrides
# (RequireConsent => consent, RequireLI => LI). On the LI basis the carve-out
# still outranks the generic LI failure.
sub _flexible_failure {
  my ($self, $tc, $vendor_id, $pid, $default_is_li) = @_;

  if ($tc->check_publisher_restriction($pid, NotAllowed, $vendor_id)) {
    return GDPR::IAB::TCFv2::Validator::Failure->new(
      code             => ReasonPublisherRestrictionNotAllowed,
      message          => "publisher restriction: purpose $pid not allowed (vendor $vendor_id)",
      purpose_id       => $pid,
      vendor_id        => $vendor_id,
      restriction_type => NotAllowed,
    );
  }

  my $is_li = $default_is_li;
  $is_li = 0 if _li_carve_out_applies($pid, $tc->policy_version);

  if    ($tc->check_publisher_restriction($pid, RequireConsent, $vendor_id))            { $is_li = 0 }
  elsif ($tc->check_publisher_restriction($pid, RequireLegitimateInterest, $vendor_id)) { $is_li = 1 }

  if ($is_li && _li_carve_out_applies($pid, $tc->policy_version)) {
    return GDPR::IAB::TCFv2::Validator::Failure->new(
      code       => ReasonLegitimateInterestNotPermittedForPurpose,
      message    => "legitimate interest not permitted for purpose $pid",
      purpose_id => $pid,
      vendor_id  => $vendor_id,
    );
  }

  return GDPR::IAB::TCFv2::Validator::Failure->new(
    code    => $is_li ? ReasonVendorNotAllowedLegitimateInterest : ReasonVendorNotAllowedConsent,
    message => $is_li
    ? "vendor $vendor_id not allowed for purpose $pid (legitimate interest)"
    : "vendor $vendor_id not allowed for purpose $pid (consent)",
    purpose_id => $pid,
    vendor_id  => $vendor_id,
  );
}

sub _li_carve_out_applies {
  my ($pid, $policy_version) = @_;

  return 1 if $pid == 1;
  return 1 if $pid >= 3 && $pid <= 6 && $policy_version >= 4;
  return 0;
}

# Inspect publisher restrictions for ($vendor_id, $pid) and return a
# Failure object when a restriction contradicts the configured basis,
# or undef when no restriction-driven failure applies.
#
# $basis: 0 = consent, 1 = legitimate interest.
#
# A NotAllowed restriction always wins (it terminates the rule for
# either basis). Beyond that, only the restriction type that
# contradicts the configured basis is reported here -- the matching
# restriction (e.g. RequireConsent on a consent-basis purpose) is a
# legal coexistence and falls through to the parser delegate.
sub _publisher_restriction_failure {
  my ($self, $tc, $vendor_id, $pid, $basis) = @_;

  if ($tc->check_publisher_restriction($pid, NotAllowed, $vendor_id)) {
    return GDPR::IAB::TCFv2::Validator::Failure->new(
      code             => ReasonPublisherRestrictionNotAllowed,
      message          => "publisher restriction: purpose $pid not allowed (vendor $vendor_id)",
      purpose_id       => $pid,
      vendor_id        => $vendor_id,
      restriction_type => NotAllowed,
    );
  }

  if ($basis == 0 && $tc->check_publisher_restriction($pid, RequireLegitimateInterest, $vendor_id)) {
    return GDPR::IAB::TCFv2::Validator::Failure->new(
      code             => ReasonPublisherRestrictionRequireLegitimateInterest,
      message          => "publisher restriction: purpose $pid requires legitimate interest (vendor $vendor_id)",
      purpose_id       => $pid,
      vendor_id        => $vendor_id,
      restriction_type => RequireLegitimateInterest,
    );
  }

  if ($basis == 1 && $tc->check_publisher_restriction($pid, RequireConsent, $vendor_id)) {
    return GDPR::IAB::TCFv2::Validator::Failure->new(
      code             => ReasonPublisherRestrictionRequireConsent,
      message          => "publisher restriction: purpose $pid requires consent (vendor $vendor_id)",
      purpose_id       => $pid,
      vendor_id        => $vendor_id,
      restriction_type => RequireConsent,
    );
  }

  return;
}


sub _make_result {
  my ($self, $ok, $failures) = @_;

  return GDPR::IAB::TCFv2::Validator::Result->new(ok => $ok, failures => $failures,);
}

1;
__END__

=encoding utf8

=head1 NAME

GDPR::IAB::TCFv2::Validator - declarative compliance checks for TC strings

=head1 SYNOPSIS

    use GDPR::IAB::TCFv2::Validator;

    my $validator = GDPR::IAB::TCFv2::Validator->new(
        vendor_id                       => 284,
        consent_purpose_ids             => [ 1, 3, 9 ],
        legitimate_interest_purpose_ids => [ 10 ],
        flexible_purpose_ids            => [ 10 ],
        verify_disclosed_vendors        => 1,
        min_tcf_policy_version          => 5,
        strict_legal_basis              => 1,
    );

    # Fail-fast: stops at the first failing rule.
    my $tc_string = '...';
    my $result = $validator->validate($tc_string);

    # Accumulate every failure for richer error reporting.
    $result = $validator->validate_all($tc_string);

    if ($result) {
        # All rules passed.
    }
    else {
        warn "Compliance failed:\n$result\n";  # stringification = reasons
        for my $reason ( $result->reasons ) {
            warn "$reason";
        }
    }

=head1 DESCRIPTION

C<GDPR::IAB::TCFv2::Validator> is a small rule engine that turns a static
"compliance policy" — required purposes, expected vendor, optional
disclosed-vendors check — into a single C<validate> / C<validate_all>
call against a TC string (or a pre-parsed L<GDPR::IAB::TCFv2> object).

Each rule produces a human-readable B<reason> on failure; reasons are
collected on a L<GDPR::IAB::TCFv2::Validator::Result> object that
overloads boolean and string contexts so it drops into typical
error-handling idioms (C<if (!$result)>, C<print "$result\n">) without
ceremony.

=head1 CONSTRUCTOR

=head2 new

    my $v = GDPR::IAB::TCFv2::Validator->new( %args );

Recognized keys:

=over 4

=item *

C<vendor_id> — the vendor whose access is being validated. Optional in
the constructor (can be supplied per call via C<< validate(..., vendor_id
=> N) >>) but B<one of the two> must be set or C<validate>/C<validate_all>
will C<croak> with C<"missing vendor_id">.

=item *

C<consent_purpose_ids> — arrayref of purpose IDs that B<must> have
vendor consent. Validated via L<GDPR::IAB::TCFv2/is_vendor_consent_allowed>.

=item *

C<legitimate_interest_purpose_ids> — arrayref of purpose IDs that B<must>
have vendor legitimate-interest. Validated via
L<GDPR::IAB::TCFv2/is_vendor_legitimate_interest_allowed>. The IAB spec
forbids LI for Purpose 1 always, and for Purposes 3-6 in TCF v2.2+;
those are enforced by the underlying parser and surface here as failures.

=item *

C<flexible_purpose_ids> — arrayref of purpose IDs that are B<flexible> per
the vendor's GVL declaration (the basis can flip if a publisher restriction
is present in the TC string). The default basis is derived structurally
from the other two lists:

=over 8

=item *

If the purpose ID also appears in C<consent_purpose_ids>, the default basis
is consent.

=item *

If the purpose ID also appears in C<legitimate_interest_purpose_ids>, the
default basis is legitimate interest.

=back

A purpose listed in C<flexible_purpose_ids> must also appear in exactly one
of the other two lists, or the constructor C<croak>s. Validated via
L<GDPR::IAB::TCFv2/is_vendor_allowed_for_flexible_purpose>.

=item *

C<verify_disclosed_vendors> — boolean. When true, the validator inspects
the TC string's Disclosed Vendors segment: if the segment is B<present>,
the vendor must appear there or the rule fails with C<"vendor N not
disclosed"> (ReasonVendorNotDisclosed). An B<absent> segment is never a
C<verify_disclosed_vendors> failure on its own — that case is owned by the
mandatory-segment rules below.

Setting C<min_tcf_policy_version> to B<5 or higher> implies
C<verify_disclosed_vendors> (it is auto-enabled), mirroring the Go
C<lib-gdpr> validator.

Independently of C<verify_disclosed_vendors>, an absent Disclosed Vendors
segment is B<mandatory> (failing with ReasonMissingDisclosedVendors) when
either:

=over 8

=item *

the TC string was created on/after the TCF v2.3 deadline (date-based,
C<2026-02-28>); or

=item *

the TC string's B<own> policy version is C<E<gt>= 5> B<and>
C<min_tcf_policy_version> is C<E<gt>= 5>. A policy-2/4 string under a
policy-5 floor fails the floor (ReasonPolicyVersionTooLow) rather than the
missing-segment rule.

=back

Otherwise an absent segment is B<silently ignored> (matches legacy
behavior).

=item *

C<strict_legal_basis> — boolean. Passed through to the underlying
C<is_vendor_*_allowed> calls (as the C<strict> named argument) so
invalid purpose IDs cause C<croak> instead of a silent failure.
Defaults to C<0>.

=back

=head1 METHODS

=head2 validate

    my $result = $validator->validate( $tc_string_or_object, %overrides );

Runs the configured rules against C<$tc_string_or_object>. Stops at
the first failing rule (B<fail-fast> mode) and returns a
L<GDPR::IAB::TCFv2::Validator::Result> carrying that one reason.

C<%overrides> can replace the constructor values for C<vendor_id>,
C<strict_legal_basis>, C<verify_disclosed_vendors>,
C<min_tcf_policy_version>, C<cmp_validator>,
C<consent_purpose_ids>, C<legitimate_interest_purpose_ids>, and
C<flexible_purpose_ids> for this call only.

The list overrides (C<consent_purpose_ids>,
C<legitimate_interest_purpose_ids>, C<flexible_purpose_ids>) do B<not>
re-validate coherence — orphan entries (a flexible pid that isn't also
in one of the basis lists) are silently dropped at runtime rather than
fatal. This makes per-call overrides forgiving for callers that
generate their lists dynamically; the constructor remains strict for
the static policy.

C<$tc_string_or_object> may be either a raw consent string or a
pre-parsed L<GDPR::IAB::TCFv2> object — handy when the same TC string
is being validated against multiple policies.

=head2 validate_all

Identical to L</validate> but runs B<every> rule and accumulates all
failures into the result. Use when you want a complete error report
rather than the first failure.

=head1 SEE ALSO

L<GDPR::IAB::TCFv2::Validator::Result> for the result-object API,
including the C<bool> / C<""> overloads and the C<$\>-aware
stringification.

L<GDPR::IAB::TCFv2> for the underlying parser and the
C<is_vendor_*_allowed> family of methods this validator is built on.

=cut

package GDPR::IAB::TCFv2::Validator::Result 0.530;

use v5.12;
use warnings;

use overload
  bool => sub { $_[0]->{ok} },
  '""' => sub {
  my $self = shift;
  return '' if $self->{ok};

  # Use $ORS (Output Record Separator) or newline as fallback
  my $sep = defined($\) ? $\ : "\n";
  return join($sep, map { $_->message } @{$self->{failures} || []});
  };

sub new {
  my ($klass, %args) = @_;

  my $self = {ok => $args{ok} || 0, failures => $args{failures} || [],};

  return bless $self, $klass;
}

sub is_valid { $_[0]->{ok} }

sub failures {
  my $self = shift;
  return @{$self->{failures} || []};
}

sub reason_codes {
  my $self = shift;
  return map { $_->code } @{$self->{failures} || []};
}

sub reasons {
  my $self = shift;
  return map { $_->message } @{$self->{failures} || []};
}

1;
__END__

=encoding utf8

=head1 NAME

GDPR::IAB::TCFv2::Validator::Result - outcome object returned by L<GDPR::IAB::TCFv2::Validator>

=head1 SYNOPSIS

    my ($validator, $tc_string) = ('...', '...');
    my $result = $validator->validate($tc_string);

    if ($result) {
        # Validation passed.
    }
    else {
        warn "$result\n";                 # one reason per line by default
        for my $reason ( $result->reasons ) {
             warn $reason;
        }
    }

    # Use Perl's output record separator to control how reasons join:
    {
        local $\ = " | ";
        print "$result";                  # "reason1 | reason2"
    }

=head1 DESCRIPTION

A small immutable carrier for the outcome of a
L<GDPR::IAB::TCFv2::Validator/validate> or
L<GDPR::IAB::TCFv2::Validator/validate_all> run. It
overloads boolean and string contexts so it drops into typical
error-handling idioms without an explicit accessor call.

=head1 OVERLOADS

=head2 Boolean

    if ($result) { ... }
    if (!$result) { ... }

True when validation passed (no rules failed); false otherwise.

=head2 Stringification

    print "$result\n";

Returns the empty string for a passing result. For a failing result,
returns the failure reasons joined by Perl's output record separator
(C<$\>); if C<$\> is undefined, reasons are joined by C<"\n">.

This means:

    print "$result\n";              # one reason per line
    local $\ = " | ";
    print "$result\n";              # "reason1 | reason2"

aligns naturally with the way C<print> would have laid out the reasons
if you had iterated and printed them yourself.

=head1 METHODS

=head2 is_valid

    my $ok = $result->is_valid;

Returns truthy for a passing result, falsy otherwise. Equivalent to the
boolean overload but available as an explicit method for callers that
prefer it.

=head2 reasons

    my @reasons = $result->reasons;

Returns the list of human-readable failure reason strings. Empty for
a passing result. Equivalent to C<map { $_-E<gt>message } $result-E<gt>failures>.

=head2 failures

    my @failures = $result->failures;

Returns the list of structured L<GDPR::IAB::TCFv2::Validator::Failure>
objects. Each failure carries a stable integer C<code>, the
human-readable C<message>, and any structured context (purpose,
vendor, restriction type, CMP). Use this when you need to react
programmatically to specific failure types.

    use GDPR::IAB::TCFv2::Validator::Reason qw<:all>;

    for my $f ( $result->failures ) {
        if ( $f->code == ReasonVendorNotAllowedConsent ) {
            handle_consent_gap( $f->purpose_id );
        }
    }

=head2 reason_codes

    my @codes = $result->reason_codes;

Returns the list of integer reason codes. Equivalent to
C<map { $_-E<gt>code } $result-E<gt>failures>; useful when only the
codes are needed (e.g. for assertions or counters).

=head1 CONSTRUCTOR

=head2 new

Internal — construct via L<GDPR::IAB::TCFv2::Validator/validate> rather
than directly.

=head1 SEE ALSO

L<GDPR::IAB::TCFv2::Validator>,
L<GDPR::IAB::TCFv2::Validator::Failure>,
L<GDPR::IAB::TCFv2::Validator::Reason>.

=cut

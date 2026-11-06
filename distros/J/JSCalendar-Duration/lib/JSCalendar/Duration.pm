package JSCalendar::Duration 0.006;
# ABSTRACT: Convert seconds to JSCalendar durations and back

use strict;
use warnings;

use Carp qw(croak);
use Exporter qw(import);

our @EXPORT = qw(seconds_to_duration duration_to_seconds);
our @EXPORT_OK = qw(seconds_to_signed_duration signed_duration_to_seconds);

# The most whole seconds we will convert in either direction.  This is the
# largest integer that a double can hold exactly, so it is safe on every Perl.
my $MAX_SECONDS = '9007199254740991'; # 2**53 - 1

sub duration_to_seconds {
  my $input = shift;

  croak("Usage: duration_to_seconds(\$duration). (Extra args provided: @_)")
    if @_;

  croak('Usage: duration_to_seconds($duration)')
    unless defined $input;

  return _duration_to_seconds($input, $input);
}

# Convert $toparse, an unsigned duration, to seconds.  $input is what the
# public function was given, which may have more to it than $toparse, and is
# used in error messages.
sub _duration_to_seconds {
  my ($input, $toparse) = @_;

  # Let's get that out of the way
  return '0' if $toparse eq 'P0D';

  my $seconds = 0;

  if ($toparse =~ /\P{ASCII}/) {
    croak("Invalid duration '$input', must be entirely ASCII");
  }

  unless ($toparse =~ s/^P//) {
    croak("Invalid duration '$input', must start with 'P'");
  }

  unless (length $toparse) {
    croak("Invalid duration '$input', no components after 'P'");
  }

  # RFC 8984 allows weeks to be followed by days and a time component, unlike
  # RFC 5545 and earlier JSCalendar drafts, where weeks had to stand alone.
  if ($toparse =~ s/^(\d+)W//) {
    $seconds += (86400 * 7 * $1);
  }

  if ($toparse =~ s/^(\d+)D//) {
    $seconds += (86400 * $1);
  }

  unless (length $toparse) {
    _assert_not_too_many_seconds($input, $seconds);
    return $seconds;
  }

  unless ($toparse =~ s/^T//) {
    croak("Invalid duration '$input', expected T here: '$toparse'");
  }

  unless (length $toparse) {
    croak("Invalid duration '$input', no components after 'T'");
  }

  my ($has_hours, $has_minutes);

  if ($toparse =~ s/^(\d+)H//) {
    $seconds += (3600 * $1);
    $has_hours = 1;
  }

  if ($toparse =~ s/^(\d+)M//) {
    $seconds += (60 * $1);
    $has_minutes = 1;
  }

  my $fraction;

  if ($toparse =~ s/^(\d+)(\.\d+)?S//) {
    (my $whole, $fraction) = ($1, $2);

    # In the grammar, dur-hour may only be followed by dur-minute, so seconds
    # can't come right after hours: PT1H1S must be PT1H0M1S.
    if ($has_hours && !$has_minutes) {
      croak("Invalid duration '$input', seconds may not follow hours without minutes");
    }

    # RFC 8984: "Fractional second values MUST NOT have trailing zeros", and
    # that includes a fraction of all zeros.
    if (defined $fraction && $fraction =~ /0\z/) {
      croak("Invalid duration '$input', fractional seconds may not end in zero");
    }

    $seconds += $whole;
  }

  if (length $toparse) {
    croak("Invalid duration '$input': confused by '$toparse'");
  }

  _assert_not_too_many_seconds($input, $seconds);

  return defined $fraction ? $seconds + $fraction : $seconds;
}

# $seconds is the whole seconds in the duration $input, added up from its
# components.  If the true total is over $MAX_SECONDS, the computed one is too,
# even if the arithmetic was inexact or overflowed to infinity, because rounding
# never carries a value past a number it can represent exactly, like 2**53.
sub _assert_not_too_many_seconds {
  my ($input, $seconds) = @_;

  if ($seconds > $MAX_SECONDS) {
    croak("Invalid duration '$input', whole seconds exceed $MAX_SECONDS");
  }
}

sub seconds_to_duration {
  my $input = shift;

  croak("Usage: seconds_to_duration(\$seconds). (Extra args provided: @_)")
    if @_;

  croak('Usage: seconds_to_duration($seconds)')
    unless defined $input;

  return _seconds_to_duration('seconds_to_duration', $input, $input);
}

# Convert $toparse, a non-negative number of seconds, to a duration.  $input is
# what the public function, named by $func, was given, which may have more to
# it than $toparse, and both are used in error messages.
sub _seconds_to_duration {
  my ($func, $input, $toparse) = @_;

  unless (length $toparse) {
    croak("Usage: $func(\$seconds). (Non-number value provided: '$input')");
  }

  my $dec = q{};

  # RFC 8984 forbids trailing zeros in the fraction, and forbids a fraction
  # that is entirely zero, so we drop them, possibly leaving nothing.
  if ($toparse =~ s/\.([0-9]+)\z//) {
    ($dec = $1) =~ s/0+\z//;
  }

  # .1 becomes "", we want 0 after
  $toparse ||= 0;

  if ($toparse && $toparse !~ /\A[0-9]+\z/) {
    croak("Usage: $func(\$seconds). (Non-number value provided: '$input')");
  }

  # Compare as strings before doing arithmetic, so oversized inputs cannot
  # overflow or lose precision.  This limit is exact even on floating-point
  # Perl builds; the fractional part is kept separately as a string.
  $toparse =~ s/\A0+(?=[0-9])//;
  if (length($toparse) > length($MAX_SECONDS)
      || (length($toparse) == length($MAX_SECONDS) && $toparse gt $MAX_SECONDS)) {
    croak("Usage: $func(\$seconds). (Whole seconds exceed $MAX_SECONDS: '$input')");
  }

  my ($durday, $durtime) = ("", "");

  # This division may be done in floating point, where the quotient can be
  # inexact.  It is still safe to truncate: below 2**53, the rounding error is
  # always less than 1/86400, the smallest amount by which a quotient can fall
  # short of the next whole day, so it can never round up to it.  Raising
  # $MAX_SECONDS would break this.
  my $days = int($toparse / 86400);
  $toparse %= 86400;

  if ($days && $days % 7 == 0 && $toparse == 0 && !length $dec) {
    return 'P' . ($days/7) . "W";
  }

  $durday = "${days}D" if $days;

  my $hours = int($toparse / 3600);
  $toparse %= 3600;

  $durtime = "${hours}H" if $hours;

  my $minutes = int($toparse / 60);
  my $seconds = $toparse % 60;

  # The grammar only permits seconds after minutes, so if we have hours and
  # seconds, we need minutes even if there are zero of them.
  $durtime .= "${minutes}M" if $minutes || ($hours && ($seconds || length $dec));

  if (length $dec) {
    $durtime .= "${seconds}.${dec}S";
  } elsif ($seconds) {
    $durtime .= "${seconds}S";
  }

  # P<zero>D
  return "P0D" unless $durday || $durtime;

  $durtime = "T$durtime" if $durtime;

  return "P" . $durday . $durtime;
}

sub signed_duration_to_seconds {
  my $input = shift;

  croak("Usage: signed_duration_to_seconds(\$duration). (Extra args provided: @_)")
    if @_;

  croak('Usage: signed_duration_to_seconds($duration)')
    unless defined $input;

  my ($sign, $duration) = $input =~ /\A([-+]?)(.*)\z/s;

  my $seconds = _duration_to_seconds($input, $duration);

  return($sign eq '-' && $seconds != 0 ? -$seconds : $seconds);
}

sub seconds_to_signed_duration {
  my $input = shift;

  croak("Usage: seconds_to_signed_duration(\$seconds). (Extra args provided: @_)")
    if @_;

  croak('Usage: seconds_to_signed_duration($seconds)')
    unless defined $input;

  my ($sign, $seconds) = $input =~ /\A([-+]?)(.*)\z/s;

  my $duration = _seconds_to_duration(
    'seconds_to_signed_duration',
    $input,
    $seconds,
  );

  return($sign eq '-' && $duration ne 'P0D' ? "-$duration" : $duration);
}

1;

=pod

=encoding UTF-8

=head1 NAME

JSCalendar::Duration - Convert seconds to JSCalendar durations and back

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use JSCalendar::Duration qw(
    seconds_to_duration
    duration_to_seconds
  );

  # 104403.1
  my $seconds = duration_to_seconds("P1DT5H0M3.1S");

  # P1D
  my $duration = seconds_to_duration('86400');

=head1 DESCRIPTION

This module converts between a duration of time as specified by seconds and
a JSCalendar Duration or SignedDuration, as defined in RFC 8984 sections 1.4.6
and 1.4.7.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 EXPORTS

=head2 seconds_to_duration

  my $duration = seconds_to_duration("86401.2");

Converts seconds to a JSCalendar duration representation.

The whole seconds must not exceed 9007199254740991 (2**53 - 1), the largest
integer in the portable exact integer range.  Larger values throw an exception.
Fractional seconds are handled separately and do not count toward this limit.

=head2 duration_to_seconds

  my $seconds = duration_to_seconds("P1DT4H");

Converts a JSCalendar duration to seconds.

The duration must not total more than 9007199254740991 (2**53 - 1) whole
seconds, the same limit as C<seconds_to_duration>.  Longer durations throw an
exception.

=head1 OPTIONAL EXPORTS

These are not exported by default, but can be requested by name.

=head2 seconds_to_signed_duration

  # -PT15M
  my $duration = seconds_to_signed_duration(-900);

Converts seconds, which may be negative, to a JSCalendar SignedDuration.
Negative values get a leading C<->.  Positive values and zero get no sign.
The magnitude has the same whole-seconds limit as C<seconds_to_duration>.

=head2 signed_duration_to_seconds

  # -900
  my $seconds = signed_duration_to_seconds("-PT15M");

Converts a JSCalendar SignedDuration, which may have a leading C<+> or C<->,
to seconds, which will be negative if the duration had a leading C<->.
The magnitude has the same whole-seconds limit as C<duration_to_seconds>.

=head1 SEE ALSO

=over 4

=item L<https://www.rfc-editor.org/rfc/rfc8984.html#section-1.4.6>

The JSCalendar Duration type, in RFC 8984.

=item L<https://www.rfc-editor.org/rfc/rfc8984.html#section-1.4.7>

The JSCalendar SignedDuration type, in RFC 8984.

=back

=head1 AUTHOR

Matthew Horsfall <wolfsage@gmail.com>

=head1 CONTRIBUTORS

=for stopwords Mohammad S Anwar Ricardo Signes

=over 4

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Ricardo Signes <rjbs@users.noreply.github.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Matthew Horsfall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 SYNOPSIS
#pod
#pod   use JSCalendar::Duration qw(
#pod     seconds_to_duration
#pod     duration_to_seconds
#pod   );
#pod
#pod   # 104403.1
#pod   my $seconds = duration_to_seconds("P1DT5H0M3.1S");
#pod
#pod   # P1D
#pod   my $duration = seconds_to_duration('86400');
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module converts between a duration of time as specified by seconds and
#pod a JSCalendar Duration or SignedDuration, as defined in RFC 8984 sections 1.4.6
#pod and 1.4.7.
#pod
#pod =head1 EXPORTS
#pod
#pod =head2 seconds_to_duration
#pod
#pod   my $duration = seconds_to_duration("86401.2");
#pod
#pod Converts seconds to a JSCalendar duration representation.
#pod
#pod The whole seconds must not exceed 9007199254740991 (2**53 - 1), the largest
#pod integer in the portable exact integer range.  Larger values throw an exception.
#pod Fractional seconds are handled separately and do not count toward this limit.
#pod
#pod =head2 duration_to_seconds
#pod
#pod   my $seconds = duration_to_seconds("P1DT4H");
#pod
#pod Converts a JSCalendar duration to seconds.
#pod
#pod The duration must not total more than 9007199254740991 (2**53 - 1) whole
#pod seconds, the same limit as C<seconds_to_duration>.  Longer durations throw an
#pod exception.
#pod
#pod =head1 OPTIONAL EXPORTS
#pod
#pod These are not exported by default, but can be requested by name.
#pod
#pod =head2 seconds_to_signed_duration
#pod
#pod   # -PT15M
#pod   my $duration = seconds_to_signed_duration(-900);
#pod
#pod Converts seconds, which may be negative, to a JSCalendar SignedDuration.
#pod Negative values get a leading C<->.  Positive values and zero get no sign.
#pod The magnitude has the same whole-seconds limit as C<seconds_to_duration>.
#pod
#pod =head2 signed_duration_to_seconds
#pod
#pod   # -900
#pod   my $seconds = signed_duration_to_seconds("-PT15M");
#pod
#pod Converts a JSCalendar SignedDuration, which may have a leading C<+> or C<->,
#pod to seconds, which will be negative if the duration had a leading C<->.
#pod The magnitude has the same whole-seconds limit as C<duration_to_seconds>.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over 4
#pod
#pod =item L<https://www.rfc-editor.org/rfc/rfc8984.html#section-1.4.6>
#pod
#pod The JSCalendar Duration type, in RFC 8984.
#pod
#pod =item L<https://www.rfc-editor.org/rfc/rfc8984.html#section-1.4.7>
#pod
#pod The JSCalendar SignedDuration type, in RFC 8984.
#pod
#pod =back
#pod
#pod =cut

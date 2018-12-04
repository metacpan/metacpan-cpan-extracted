package JSCalendar::Duration;
# ABSTRACT: Convert seconds to JSCalendar durations and back
$JSCalendar::Duration::VERSION = '0.002';
use strict;
use warnings;

use Carp qw(croak);
use Exporter qw(import);

our @EXPORT = qw(seconds_to_duration duration_to_seconds);

sub duration_to_seconds {
  my $input = shift;

  croak("Usage: duration_to_seconds(\$duration). (Extra args provided: @_)")
    if @_;

  croak('Usage: duration_to_seconds($duration)')
    unless defined $input;

  # Let's get that out of the way
  return '0' if $input eq 'P0D';

  my $toparse = $input;

  my $seconds = 0;

  unless ($toparse =~ s/^P//) {
    croak("Invalid duration '$input', must start with 'P'");
  }

  if ($toparse =~ s/^(\d+)D//) {
    $seconds += (86400 * $1);
  }

  return $seconds unless $toparse;

  unless ($toparse =~ s/^T//) {
    croak("Invalid duration '$input', expected T here: '$toparse'");
  }

  if ($toparse =~ s/^(\d+)H//) {
    $seconds += (3600 * $1);
  }

  if ($toparse =~ s/^(\d+)M//) {
    $seconds += (60 * $1);
  }

  if ($toparse =~ s/^(\d+(?:\.\d+)?)S//) {
    $seconds += $1;
  }

  if ($toparse) {
    croak("Invalid duration '$input': confused by '$toparse'");
  }

  return $seconds;
}

sub seconds_to_duration {
  my $input = shift;

  croak("Usage: seconds_to_duration(\$seconds). (Extra args provided: @_)")
    if @_;

  croak('Usage: seconds_to_duration($seconds)')
    unless defined $input;

  my $toparse = $input;

  my $dec;

  $dec = $1 if $toparse =~ s/\.(\d+)$//;

  # .1 becomes "", we want 0 after
  $toparse ||= 0;

  if ($toparse && $toparse !~ /^\d+$/) {
    croak("Usage: seconds_to_duration(\$seconds). (Non-number value provided: '$input'");
  }

  my ($durday, $durtime) = ("", "");

  my $days = 0;

  while ($toparse >= 86400) {
    $days++;
    $toparse -= 86400;
  }

  $durday = "${days}D" if $days;

  my $hours = 0;

  while ($toparse >= 3600) {
    $hours++;
    $toparse -= 3600;
  }

  $durtime = "${hours}H" if $hours;

  my $minutes = 0;

  while ($toparse >= 60) {
    $minutes++;
    $toparse -= 60;
  }

  $durtime .= "${minutes}M" if $minutes;

  my $seconds = 0;

  while ($toparse >= 1) {
    $seconds++;
    $toparse -= 1;
  }

  $durtime .= "${seconds}" if $seconds;

  if ($dec) {
    $durtime .= $durtime ? ".${dec}S" : "0.${dec}S";
  } elsif ($seconds) {
    $durtime .= "S";
  }

  # P<zero>D
  return "P0D" unless $durday || $durtime;

  $durtime = "T$durtime" if $durtime;

  return "P" . $durday . $durtime;
}

1;

=pod

=encoding UTF-8

=head1 NAME

JSCalendar::Duration - Convert seconds to JSCalendar durations and back

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use JSCalendar::Duration qw(
    seconds_to_duration
    duration_to_seconds
  );

  # 104403.1
  my $seconds = duration_to_seconds("P1DT5H3.1S");

  # P1D
  my $duration = seconds_to_duration('86400');

=head1 DESCRIPTION

This module converts between a duration of time as specified by seconds and
a JSCalendar duration (L<https://tools.ietf.org/html/draft-ietf-calext-jscalendar-00#section-3.2.3>).

=head1 EXPORTS

=head2 seconds_to_duration

  my $duration = seconds_to_duration("86401.2");

Converts seconds to a JSCalendar duration representation.

=head2 duration_to_seconds

  my $seconds = duration_to_seconds("P1DT4H");

Converts a JSCalendar duration to seconds.

=head1 SEE ALSO

=over 4

=item L<https://tools.ietf.org/html/draft-ietf-calext-jscalendar-00#section-3.2.3>

The JSCalendar duration spec.

=back

=head1 AUTHOR

Matthew Horsfall <wolfsage@gmail.com>

=head1 CONTRIBUTOR

=for stopwords Mohammad S Anwar

Mohammad S Anwar <mohammad.anwar@yahoo.com>

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
#pod   my $seconds = duration_to_seconds("P1DT5H3.1S");
#pod
#pod   # P1D
#pod   my $duration = seconds_to_duration('86400');
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module converts between a duration of time as specified by seconds and
#pod a JSCalendar duration (L<https://tools.ietf.org/html/draft-ietf-calext-jscalendar-00#section-3.2.3>).
#pod
#pod =head1 EXPORTS
#pod
#pod =head2 seconds_to_duration
#pod
#pod   my $duration = seconds_to_duration("86401.2");
#pod
#pod Converts seconds to a JSCalendar duration representation.
#pod
#pod =head2 duration_to_seconds
#pod
#pod   my $seconds = duration_to_seconds("P1DT4H");
#pod
#pod Converts a JSCalendar duration to seconds.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over 4
#pod
#pod =item L<https://tools.ietf.org/html/draft-ietf-calext-jscalendar-00#section-3.2.3>
#pod
#pod The JSCalendar duration spec.
#pod
#pod =back
#pod
#pod =cut

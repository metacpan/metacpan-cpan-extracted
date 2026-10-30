package Langertha::Raider::Cron;
# ABSTRACT: Internal five-field cron expressions: validation, the next fire time and Claude Code's jitter
our $VERSION = '0.504';
use strict;
use warnings;
use Carp qw( croak );
use Digest::SHA ();
use POSIX ();


my %RANGE = (
  minute => [ 0, 59 ],
  hour   => [ 0, 23 ],
  dom    => [ 1, 31 ],
  month  => [ 1, 12 ],
  dow    => [ 0, 7 ],
);
my @FIELDS = qw( minute hour dom month dow );

# How far ahead a match is looked for: expressions that name a day that
# does not exist (31 February) never match.
my $HORIZON_YEARS = 8;


sub parse {
  my ( $self, $text ) = @_;
  return ( undef, 'no cron expression given' ) unless defined $text && !ref $text && $text =~ /\S/;
  my @field = split ' ', $text;
  return ( undef, 'expected five fields (minute hour day-of-month month day-of-week), got '.scalar(@field) )
    unless @field == 5;
  my %parsed;
  for my $i ( 0 .. 4 ) {
    my $name = $FIELDS[$i];
    my ( $set, $error ) = $self->_field( $name, $field[$i] );
    return ( undef, $error ) if defined $error;
    $parsed{$name} = $set;
  }
  # 7 is Sunday too.
  if ( delete $parsed{dow}{7} ) {
    $parsed{dow}{0} = 1;
  }
  $parsed{dom_star} = $field[2] =~ /\A\*/ ? 1 : 0;
  $parsed{dow_star} = $field[4] =~ /\A\*/ ? 1 : 0;
  return \%parsed;
}

sub _field {
  my ( $self, $name, $text ) = @_;
  my ( $min, $max ) = @{ $RANGE{$name} };
  my %set;
  for my $part ( split /,/, $text, -1 ) {
    return ( undef, 'empty entry in the '.$name.' field' ) unless length $part;
    my ( $range, $step ) = split m{/}, $part, 2;
    return ( undef, 'bad step in the '.$name.' field: '.$part )
      if defined $step && $step !~ /\A[1-9][0-9]*\z/;
    my ( $from, $to );
    if ( $range eq '*' ) {
      ( $from, $to ) = ( $min, $name eq 'dow' ? 6 : $max );
    }
    elsif ( $range =~ /\A([0-9]+)-([0-9]+)\z/ ) {
      ( $from, $to ) = ( $1, $2 );
    }
    elsif ( $range =~ /\A([0-9]+)\z/ ) {
      ( $from, $to ) = ( $1, defined $step ? $max : $1 );
    }
    else {
      return ( undef, 'unsupported syntax in the '.$name.' field: '.$part );
    }
    return ( undef, 'out of range in the '.$name.' field ('.$min.'-'.$max.'): '.$part )
      if $from < $min || $to > $max || $from > $to;
    $step //= 1;
    for ( my $v = $from; $v <= $to; $v += $step ) {
      $set{$v} = 1;
    }
  }
  return \%set;
}


sub validate {
  my ( $self, $text ) = @_;
  my ( $parsed, $error ) = $self->parse($text);
  return $error unless $parsed;
  return $self->next( $text, 0 ) ? undef : 'the expression does not match any date';
}


sub next {
  my ( $self, $text, $after ) = @_;
  my ( $p ) = $self->parse($text);
  return unless $p;
  my $t = ( int( $after / 60 ) + 1 ) * 60;    # the next full minute
  my $limit = $after + $HORIZON_YEARS * 366 * 86400;
  while ( $t <= $limit ) {
    my ( $min, $hour, $mday, $mon, $year, $wday ) = ( localtime $t )[ 1, 2, 3, 4, 5, 6 ];
    $mon++;
    unless ( $p->{month}{$mon} ) {
      $t = $self->_jump( $t, 0, 0, 0, 1, $mon, $year );    # the first of the next month
      next;
    }
    unless ( $self->_day_matches( $p, $mday, $wday ) ) {
      $t = $self->_jump( $t, 0, 0, 0, $mday + 1, $mon - 1, $year );
      next;
    }
    unless ( $p->{hour}{$hour} ) {
      $t = $self->_jump( $t, 0, 0, $hour + 1, $mday, $mon - 1, $year );
      next;
    }
    unless ( $p->{minute}{$min} ) {
      $t += 60;
      next;
    }
    return $t;
  }
  return;
}

# The local time given, normalised by mktime; never at or before $t (the
# hour that repeats when the clock goes back).
sub _jump {
  my ( $self, $t, @time ) = @_;
  my $to = POSIX::mktime( @time, -1 );
  return defined $to && $to > $t ? $to : $t + 3600;
}

sub _day_matches {
  my ( $self, $p, $mday, $wday ) = @_;
  my ( $dom, $dow ) = ( $p->{dom}{$mday}, $p->{dow}{$wday} );
  return ( $p->{dom_star} || $p->{dow_star} ) ? ( $dom && $dow ) : ( $dom || $dow );
}


sub matches {
  my ( $self, $text, $at ) = @_;
  my $minute = int( $at / 60 ) * 60;
  my $next = $self->next( $text, $minute - 60 ) // return 0;
  return $next == $minute ? 1 : 0;
}


sub jitter {
  my ( $self, $text, $scheduled, %o ) = @_;
  my $fraction = $self->_fraction( $o{key} );
  if ( $o{recurring} ) {
    my $next = $self->next( $text, $scheduled ) // return 0;
    my $gap  = $next - $scheduled;
    return -15 if $gap == 300;
    my $span = $gap / 2;
    $span = 1800 if $span > 1800;
    return int( $fraction * $span );
  }
  my $minute = ( localtime $scheduled )[1];
  return 0 unless $minute == 0 || $minute == 30;
  return -int( $fraction * 90 );
}

# A number in [0, 1) that is the same for the same key.
sub _fraction {
  my ( $self, $key ) = @_;
  $key //= '';
  return unpack( q{N}, Digest::SHA::sha1($key) ) / 4_294_967_296;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Cron - Internal five-field cron expressions: validation, the next fire time and Claude Code's jitter

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $cron = 'Langertha::Raider::Cron';

    my $error = $cron->validate('*/5 * * * *');            # undef, or the reason
    my $at    = $cron->next( '0 9 * * 1-5', time );        # epoch of the next match, local time
    my $when  = $cron->jittered( '7 * * * *', $at, key => 'cron_1', recurring => 1 );

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The cron arithmetic behind C<cron_create> (ADR 0031): the five-field
expressions Claude Code's C<CronCreate> takes, in local time, and the
jitter it adds to the run times. Everything works on epoch seconds, so a
caller with a clock of its own (the scheduler's C<now>) is not tied to
the real time.

An expression is C<minute hour day-of-month month day-of-week>. Every field
takes C<*>, a value, a range (C<1-5>), a step (C<*/15>, C<1-30/5>) and
comma-separated lists of those. Day-of-week is C<0> or C<7> for Sunday up
to C<6> for Saturday. The extended syntax -- C<L>, C<W>, C<?>, C<#> and the
names C<MON> or C<JAN> -- is not supported. When both day-of-month and
day-of-week are constrained, a day matches if either field matches (vixie
cron).

=head2 parse

    my $parsed = Langertha::Raider::Cron->parse('0 9 * * 1-5');
    my ( $parsed, $error ) = Langertha::Raider::Cron->parse('61 * * * *');

The expression as a hash reference, or nothing and the reason: for each of
C<minute>, C<hour>, C<dom>, C<month> and C<dow> a hash reference of the
values that match, and C<dom_star> and C<dow_star> (true when that field
starts with C<*>).

=head2 validate

    my $error = Langertha::Raider::Cron->validate($text);

Undef for an expression that parses and matches some date within the next
years, else the reason (C<expected five fields ...>, C<does not match any
date>).

=head2 next

    my $at = Langertha::Raider::Cron->next( $text, $epoch );

The first minute after C<$epoch> that the expression matches, as epoch
seconds in local time; nothing when there is none within eight years or
the expression is invalid.

=head2 matches

    my $yes = Langertha::Raider::Cron->matches( $text, $epoch );

True when the minute of C<$epoch> matches the expression.

=head2 jitter

    my $seconds = Langertha::Raider::Cron->jitter(
      $text, $scheduled, key => 'cron_1', recurring => 1,
    );

The seconds added to the scheduled time C<$scheduled> (epoch) of a job, as
Claude Code shifts runs so that many sessions do not call the API at the
same moment. The shift is a fixed fraction of the span allowed, taken from
C<key> (the job's ID), so the same job always runs the same number of
seconds off:

=over

=item * A recurring job runs late by up to half the gap to its next run,
at most 30 minutes (C<7,37 * * * *> by 0 to 15 minutes, an hourly or daily
job by 0 to 30).

=item * Except a job that runs every five minutes (a gap of exactly 300
seconds): it runs 15 seconds sooner, so that a run does not start after the
five-minute prompt cache has expired.

=item * A one-shot job on the hour or the half hour runs up to 90 seconds
early; any other minute is not shifted.

=back

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::CronTools>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut

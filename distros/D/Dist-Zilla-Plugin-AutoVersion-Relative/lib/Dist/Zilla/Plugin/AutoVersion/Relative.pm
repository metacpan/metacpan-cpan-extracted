use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::AutoVersion::Relative;

our $VERSION = '1.001001';

# ABSTRACT: Time-Relative versioning

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose 1.09 qw( has around with );
use MooseX::Types::Moose qw( Int Str );
use MooseX::Types::DateTime qw( TimeZone Duration Now );
use MooseX::StrictConstructor 0.10;

use Const::Fast qw( const );

const my $MONTHS_IN_YEAR => 12;

const my $DAYS_IN_MONTH => 31;    # This is assumed, makes our years square.

with( 'Dist::Zilla::Role::VersionProvider', 'Dist::Zilla::Role::TextTemplate' );

use DateTime ();
use namespace::autoclean;

















has major => ( isa => Int, is => 'ro', default => 1 );
has minor => ( isa => Int, is => 'ro', default => 1 );
has format => (    ## no critic (RequireInterpolationOfMetachars)
  isa     => Str,
  is      => 'ro',
  default => q|{{ sprintf('%d.%02d%04d%02d', $major, $minor, days, hours) }}|,
);































has year      => ( isa => Int,      is     => 'ro', default => 2000 );
has month     => ( isa => Int,      is     => 'ro', default => 1 );
has day       => ( isa => Int,      is     => 'ro', default => 1 );
has hour      => ( isa => Int,      is     => 'ro', default => 0 );
has minute    => ( isa => Int,      is     => 'ro', default => 0 );
has second    => ( isa => Int,      is     => 'ro', default => 0 );
has time_zone => ( isa => TimeZone, coerce => 1,    is      => 'ro', predicate => 'has_time_zone' );















has '_release_time' => ( isa => 'DateTime', coerce => 1, is => 'ro', lazy_build => 1 );
has '_current_time' => ( isa => 'DateTime', coerce => 1, is => 'ro', lazy_build => 1 );
has 'relative' => ( isa => Duration, coerce => 1, is => 'ro', lazy_build => 1 );

if ( __PACKAGE__->can('dump_config') ) {
  around dump_config => sub {
    my ( $orig, $self, @args ) = @_;
    my $config = $self->$orig(@args);
    my $localconf = $config->{ +__PACKAGE__ } = {};

    $localconf->{major}       = $self->major;
    $localconf->{minor}       = $self->minor;
    $localconf->{format}      = $self->format;
    $localconf->{relative_to} = {
      year      => $self->year,
      month     => $self->month,
      day       => $self->day,
      hour      => $self->hour,
      minute    => $self->minute,
      second    => $self->second,
      time_zone => q{} . $self->time_zone->name,
    };

    $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
      unless __PACKAGE__ eq ref $self;

    return $config;

  };
}





sub _build__release_time {
  my $self = shift;
  return DateTime->new(
    year   => $self->year,
    month  => $self->month,
    day    => $self->day,
    hour   => $self->hour,
    minute => $self->minute,
    second => $self->second,
    ( ( $self->has_time_zone ) ? ( time_zone => $self->time_zone ) : () ),
  );
}





sub _build__current_time {
  return DateTime->now;
}





sub _build_relative {
  my $self = shift;
  my $x    = $self->_current_time->subtract_datetime( $self->_release_time );
  return $x;
}







{
  my $av_track = 0;

  sub provide_version {
    my ($self) = @_;
    $av_track++;

    my ( $y, $m, $d, $h, undef, undef ) = $self->relative->in_units( 'years', 'months', 'days', 'hours', 'minutes', 'seconds' );

    my ($days_square) = sub() {
      ( ( ( ( $y * $MONTHS_IN_YEAR ) + $m ) * $DAYS_IN_MONTH ) + $d );
    };
    my ($days_accurate) = sub() {
      $self->_current_time->delta_days( $self->_release_time )->in_units('days');
    };

    my $tokens = {
      major    => \( $self->major ),
      minor    => \( $self->minor ),
      relative => \( $self->relative ),
      cldr     => sub($) {
        my ($format) = shift;
        $self->_current_time->format_cldr($format);
      },
      days          => $days_accurate,
      days_square   => $days_square,
      days_accurate => $days_accurate,
      hours         => sub() { $h },
    };

    my $version = $self->fill_in_string( $self->format, $tokens, { 'package' => "AutoVersion::_${av_track}_", }, );
    return $version;
  }
}






















































no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AutoVersion::Relative - Time-Relative versioning

=head1 VERSION

version 1.001001

=head1 SYNOPSIS

Like all things, time is relative.
This plugin is to allow you to auto-increment versions based on a relative time point.

It doesn't do it all for you, you can choose, its mostly like L<< The C<AutoVersion> Plugin|Dist::Zilla::Plugin::AutoVersion >>
except there's a few more user-visible entities, and a few more visible options.

=head1 CONFIGURATION

To configure this, you specify the date that the version is to be
relative to.

=head2 Serving Suggestion

  [AutoVersion::Relative]
  major = 1
  minor = 1
  year  = 2009 ;  when we did our last major rev
  month = 08   ;   "           "
  day   = 23   ;   "           "
  hour  = 05   ;   "           "
  minute = 30  ;   "           "
  second = 00  ;  If you're that picky.

  time_zone = Pacific/Auckland  ;  You really want to set this.

   ; 1.0110012
  format = {{$major}}.{{sprintf('%02d%04d%02d', $minor, days, hours }}

For the list of tuneables and how to use them, see
 L</ATTRIBUTES> and L</DATE ATTRIBUTES>

=head1 FORMATTING

There are a handful of things we inject into the template for you

  # Just to give you an idea, you don't really want to be using this though.
  {{ $major }}.{{ $minor }}{{ days }}{{ hours }}{{ $relative->seconds }}

See L</FORMAT FIELDS> for the available fields and their use.

=head1 WARNING

If you don't specify Y/M/D, it will default to Jan 01, 2000 , because I
couldn't think of a more sane default. But you're setting that anyway, because
if you don't,you be cargo cultin' the bad way

=head1 ATTRIBUTES

=head2 major

=head2 major = 1

=head2 minor

=head2 minor = 1

=head2 format

=head2 format = {{ sprintf('%d.%02d%04d%02d', $major, $minor, days, hours) }}

See L</FORMATING>

=head1 DATE ATTRIBUTES

=head2 year

=head2 year = 2000

=head2 month

=head2 month = 1

=head2 day

=head2 day = 1

=head2 minute

=head2 minute = 0

=head2 second

=head2 second = 0

=head2 time_zone

You want this.

Formatting is like, "Pacific/Auckland" , or merely "+1200" format.

=head1 FORMAT FIELDS

=head2 $major

The value set for major

=head2 $minor

The value set for minor

=head2 $relative

A L<< C<DateTime::Duration>|DateTime::Duration >> object

=head2 cldr

=head2 cldr($ARG)

CLDR for the current time. See L<DateTime/format_cldr>

=head2 days

See L</days_accurate>

Used to use the algorithm as used in L</days_square> but uses the algorithm  in L</days_accurate> since 0.03000000

=head2 days_square

An approximation of the number of days passed since milestone.

Note that for this approximation, it is assumed all months are 31 days long, and years as such,
have 372 days.

This is a legacy way of computing dates, superseded by days_accurate since 0.03000000

=head2 days_accurate

The number of days passed since the milestone.

=head2 hours

The remainder number of hours elapsed.

=head1 METHODS

=head2 provide_version

returns the formatted version string to satisfy the roles.

=head1 ATTRIBUTE METHODS

=head2 has_time_zone <- predicate('time_zone')

=head1 PRIVATE ATTRIBUTES

=head2 _release_time

=head2 _release_time DateTime[ro]

=head2 _current_time

=head2 _current_time DateTime[ro]

=head2 relative

=head2 relative Duration[ro]

=head1 PRIVATE BUILDERS

=head2 _build__release_time

=head2 _build__current_time

=head2 _build_relative

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

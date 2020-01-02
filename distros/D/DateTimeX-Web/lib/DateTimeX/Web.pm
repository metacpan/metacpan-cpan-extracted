package DateTimeX::Web;

use strict;
use warnings;
use Carp;

our $VERSION = '0.09';

use DateTime;
use DateTime::Locale;
use DateTime::TimeZone;
use DateTime::Format::Strptime;
use DateTime::Format::Mail;
use DateTime::Format::W3CDTF;
use DateTime::Format::MySQL;
use DateTime::Format::HTTP;
use Scalar::Util qw( blessed );

sub _parse_options {
  my $self = shift;

  if ( @_ == 1 ) {
    return %{$_[0]} if ref $_[0] eq 'HASH';
    return @{$_[0]} if ref $_[0] eq 'ARRAY';
  }
  croak "Odd number of elements in hash assignment" if @_ % 2;
  return @_;
}

sub new {
  my $class = shift;

  my %config = $class->_parse_options(@_);

  $config{on_error} ||= 'croak';

  my $self = bless {
    config => \%config,
    format => {
      mail  => DateTime::Format::Mail->new( loose => 1 ),
      wwwc  => DateTime::Format::W3CDTF->new,
      mysql => DateTime::Format::MySQL->new,
      http  => 'DateTime::Format::HTTP',  # ::HTTP has no 'new'
    },
    parser => {},
  }, $class;

  $self->time_zone( $config{time_zone} || delete $config{timezone} || 'UTC' );
  $self->locale( $config{locale} || 'en-US' );

  $self;
}

sub format {
  my ($self, $name, $package) = @_;

  if ( $package ) {
    if ( ref $package ) {
      $self->{format}->{lc $name} = $package;
    }
    else {
      unless ( $package =~ s/^\+// ) {
        $package =~ s/^DateTime::Format:://;
        $package = "DateTime::Format\::$package";
      }
      eval "require $package;";
      croak $@ if $@;
      $self->{format}->{lc $name} =
        ( $package->can('new') ) ? $package->new : $package;
    }
  }
  $self->{format}->{lc $name};
}

sub time_zone {
  my ($self, $zone) = @_;

  if ( $zone ) {
    $self->{config}->{time_zone} =
      ( blessed $zone && $zone->isa('DateTime::TimeZone') )
        ? $zone
        : DateTime::TimeZone->new( name => $zone );
  }
  $self->{config}->{time_zone};
}

sub locale {
  my ($self, $locale) = @_;

  if ( $locale ) {
    $self->{config}->{locale} =
      ( blessed $locale && ($locale->isa('DateTime::Locale::root') || $locale->isa('DateTime::Locale::FromData') ) ) 
        ? $locale
        : DateTime::Locale->load( $locale );
  }
  $self->{config}->{locale};
}

{
    my @constructors = qw(now today last_day_of_month from_day_of_year);
    for my $method (@constructors) {
        my $code = sub {
            my $self = shift;

            my %options = $self->_parse_options(@_);

            $self->_merge_config( \%options );

            my $dt = eval { DateTime->$method( %options ) };
            $self->_error( $@ ) if $@;
            return $dt;
        };

        no strict 'refs';
        *{$method} = $code;
    }
}

sub from {
  my $self = shift;

  my %options = $self->_parse_options(@_);

  return $self->from_epoch( %options ) if $options{epoch};
  return $self->from_object( %options ) if $options{object};

  $self->_merge_config( \%options );

  my $dt = eval { DateTime->new( %options ) };
  $self->_error( $@ ) if $@;
  return $dt;
}

sub from_epoch {
  my $self  = shift;
  my $epoch = shift;
     $epoch = shift if $epoch eq 'epoch';
  my %options = $self->_parse_options(@_);

  $self->_merge_config( \%options );

  my $dt = eval { DateTime->from_epoch( epoch => $epoch, %options ) };
  $self->_error( $@ ) if $@;

  return $dt;
}

sub from_object {
  my $self  = shift;
  my $object = shift;
     $object = shift if $object eq 'object';
  my %options = $self->_parse_options(@_);

  $self->_merge_config( \%options );

  my $orig_time_zone;
  if (my $time_zone = delete $options{time_zone}) {
      if ($object->can('set_time_zone')) {
          $orig_time_zone = $object->time_zone;
          $object->set_time_zone($time_zone);
      }
  }

  my $dt = eval { DateTime->from_object( object => $object, %options ) };
  $self->_error( $@ ) if $@;

  if ($orig_time_zone) {
      $object->set_time_zone($orig_time_zone);
  }

  return $dt;
}

sub from_rss   { shift->parse_as( wwwc  => @_ ); }
sub from_mail  { shift->parse_as( mail  => @_ ); }
sub from_mysql { shift->parse_as( mysql => @_ ); }
sub from_http  { shift->parse_as( http  => @_ ); }

*from_wwwc  = \&from_rss;
*from_rss20 = \&from_mail;

sub parse_as {
  my ($self, $formatter, $string, @args) = @_;

  my %options = $self->_parse_options(@args);

  $self->_load( $formatter );

  my $dt = eval { $self->format($formatter)->parse_datetime( $string ) };
  if ( $@ ) {
    $self->_error( $@ );
  }
  else {
    $self->_merge_config( \%options );
    $self->_set_config( $dt, \%options );
    return $dt;
  }
}

sub parse {
  my ($self, $pattern, $string, @args) = @_;

  my %options = $self->_parse_options(@args);

  unless ( $self->{parser}->{$pattern} ) {
    $self->_merge_config( \%options );
    $options{pattern} = $pattern;
    my $parser = DateTime::Format::Strptime->new( %options );
    $self->{parser}->{$pattern} = $parser;
  }
  my $dt = eval { $self->{parser}->{$pattern}->parse_datetime( $string ) };
  if ( $@ ) {
    $self->_error( $@ );
  }
  else {
    $self->_set_config( $dt, \%options );
    return $dt;
  }
}

*strptime = \&parse;

sub for_rss   { shift->render_as( wwwc  => @_ ); }
sub for_mail  { shift->render_as( mail  => @_ ); }
sub for_mysql { shift->render_as( mysql => @_ ); }
sub for_http  { shift->render_as( http  => @_ ); }

*for_wwwc  = \&for_rss;
*for_rss20 = \&for_mail;

sub render_as {
  my ($self, $formatter, @args) = @_;

  $self->_load( $formatter );

  my $dt = $self->_datetime( @args );

  my $str = eval { $self->format($formatter)->format_datetime( $dt ) };
  $self->_error( $@ ) if $@;
  return $str;
}

sub _merge_config {
  my ($self, $options) = @_;

  foreach my $key (qw( time_zone locale )) {
    next unless defined $self->{config}->{$key};
    next if defined $options->{$key};
    $options->{$key} = $self->{config}->{$key};
  }
}

sub _datetime {
  my $self = shift;

  return $self->now unless @_;
  return $_[0] if @_ == 1 && blessed $_[0] && $_[0]->isa('DateTime');
  return $self->from( @_ );
}

sub _load {
  my ($self, $formatter) = @_;

  unless ( $self->format($formatter) ) {
    $self->format( $formatter => "DateTime::Format\::$formatter" );
  }
}

sub _set_config {
  my ($self, $dt, $options) = @_;

  $options ||= $self->{config};

  foreach my $key (qw( time_zone locale )) {
    my $func = "set_$key";
    $dt->$func( $options->{$key} ) if $options->{$key};
  }
}

sub _error {
  my ($self, $message) = @_;

  my $on_error = $self->{config}->{on_error};

  return if $on_error eq 'ignore';
  return $on_error->( $message ) if ref $on_error eq 'CODE';

  local $Carp::CarpLevel = 1;
  croak $message;
}

1;

__END__

=head1 NAME

DateTimeX::Web - DateTime factory for web apps

=head1 SYNOPSIS

  use DateTimeX::Web

  # create a factory.
  my $dtx = DateTimeX::Web->new(time_zone => 'Asia/Tokyo');

  # then, grab a DateTime object from there.
  my $obj = $dtx->now;

  # with arguments for a DateTime constructor.
  my $obj = $dtx->from(year => 2008, month => 2, day => 9);

  # or with epoch (you don't need 'epoch =>' as it's obvious).
  my $obj = $dtx->from_epoch(time);

  # or with a WWWC datetime format string.
  my $obj = $dtx->from_rss('2008-02-09T01:00:02');

  # actually you can use any Format plugins.
  my $obj = $dtx->parse_as(MySQL => '2008-02-09 01:00:02');

  # of course you may need to parse with strptime.
  my $obj = $dtx->parse('%Y-%m-%d', $string);

  # you may want to create a datetime string for HTTP headers.
  my $str = $dtx->for_http;

  # or for emails (you can pass an arbitrary DateTime object).
  my $str = $dtx->for_mail($dt);

  # or for database (with arguments for a DateTime constructor).
  my $str = $dtx->for_mysql(year => 2007, month => 3, day => 3);

  # actually you can use any Format plugins.
  my $str = $dtx->render_as(MySQL => $dt);

  # you want finer control?
  my $str = $dtx->format('mysql')->format_date($dt);

=head1 DESCRIPTION

The DateTime framework is quite useful and complete. However, sometimes it's a bit too strict and cumbersome. Also, we usually need to load too many common DateTime components when we build a web application. That's not DRY.

So, here's a factory to make it sweet. If you want more chocolate or cream, help yourself. The DateTime framework boasts a variety of flavors.

=head1 METHODS

=head2 new

creates a factory object. If you pass a hash, or a hash reference, it will be passed to a DateTime constructor. You usually want to provide a sane "time_zone" option.

Optionally, you can pass an "on_error" option ("ignore"/"croak"/some code reference) to the constructor. DateTimeX::Web croaks by default when DateTime spits an error. If "ignore" is set, DateTimeX::Web would ignore the error and return undef. If you want finer control, provide a code reference.

=head2 format

takes a formatter's base name and returns the corresponding DateTime::Format:: object. You can pass an optional formatter package name/object to replace the previous formatter (or to add a new one).

=head2 time_zone, locale

returns the current time zone/locale object of the factory, which would be passed to every DateTime object it creates. You can pass an optional time zone/locale string/object to replace.

=head1 METHODS TO GET A DATETIME OBJECT

=head2 now, today, from_epoch, from_object, from_day_of_year, last_day_of_month

returns a DateTime object as you expect.

=head2 from

takes arguments for a DateTime constructor and returns a DateTime object. Also, You can pass (epoch => time) pair for convenience.

=head2 from_rss, from_wwwc

takes a W3CDTF (ISO 8601) datetime string used by RSS 1.0 etc, and returns a DateTime object.

=head2 from_mail, from_rss20

takes a RFC2822 compliant datetime string used by email, and returns a DateTime object.

=head2 from_mysql

takes a MySQL datetime string, and returns a DateTime object. 

=head2 from_http

takes a HTTP datetime string, and returns a DateTime object. 

=head2 parse_as

takes a name of DateTime::Format plugin and some arguments for it, and returns a DateTime object.

=head2 parse, strptime

takes a strptime format string and a datetime string, and returns a DateTime object.

=head1 METHODS TO GET A DATETIME STRING

=head2 for_rss, for_wwwc

may or may not take a DateTime object (or arguments for a DateTime constructor), and returns a W3CDTF datetime string.

=head2 for_mail, for_rss20

the same as above but returns a RFC2822 datetime string.

=head2 for_mysql

the same as above but returns a MySQL datetime string.

=head2 for_http

the same as above but returns a HTTP datetime string.

=head2 render_as

takes a name of DateTime::Format plugin and the same thing(s) as above, and returns a formatted string.

=head1 SEE ALSO

L<DateTime>, L<DateTime::Format::Mail>, L<DateTime::Format::MySQL>, L<DateTime::Format::W3CDFT>, L<DateTime::Format::HTTP>, L<DateTime::Format::Strptime>, L<DateTime::TimeZone>, L<DateTime::Locale>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

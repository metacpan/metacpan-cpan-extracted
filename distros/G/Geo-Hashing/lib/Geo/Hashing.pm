#!/usr/bin/perl -w
#
# $Id: Hashing.pm 257 2008-06-25 02:02:19Z dan $
#

package Geo::Hashing;

use strict;
use warnings;
use Carp;
use Digest::MD5 qw/md5_hex/;

our $VERSION = '0.06';

=head1 NAME

Geo::Hashing - Perl library to calculate Geohashing points

=head1 SYNOPSIS

  use Geo::Hashing;
  my $g = new Geo::Hashing(lat => 37, lon => -122, date => "2008-05-24");
  printf "Today's location is at %.6f, %.6f.\n", $g->lat, $g->lon;

=head1 DESCRIPTION

This module allows calculating the locaiton of Geohashes as described 
in http://wiki.xkcd.com/geohashing/Main_Page.

=head1 METHODS

=cut

=head2 new

Create a new Geo::Hashing object.  

=cut

sub new {
  my $class = shift;
  my %p = @_;

  my $self = {_lat => 0, _lon => 0, _dlat => 0, _dlon => 0, _debug => 0};
  bless $self, $class;

  $self->{_date} = sprintf("%04d-%02d-%02d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3]);

  {
    no strict 'subs';
    foreach (qw/debug source lat lon date use_30w_rule djia/) {
      if (exists $p{$_}) {
        $self->_log("Setting $_ to $p{$_}");
        $self->$_($p{$_});
      }
    }
  }

  unless ($p{source}) {
    $self->source('peeron');
  }

  $self->_log("Using", $self->source, "as the DJIA source");

  return $self;
}

=head2 lat

Set or get the points latitude.  When settings, only the integer portion is
considered.  Set to undef to just get the offset.

=cut

sub lat {
  my $self = shift;
  my $lat = shift;

  if (defined $lat) {
    if ($lat =~ /^-?\d+(?:\.\d+)?$/ and $lat > -180 and $lat < 180) {
      $self->{_lat} = $lat ne "-0" ? int($lat) : "-0";
      $self->_update();
    } else {
      croak "Invalid latitude ($lat)!";
    }
  }

  return undef unless defined $self->{_dlat} and defined $self->{_dlon};

  return $self->{_lat} eq "-0" || $self->{_lat} < 0 ? 
                     $self->{_lat} - $self->{_dlat} : 
                     $self->{_lat} + $self->{_dlat};
}

=head2 lon

Set or get the points longitude.  When settings, only the integer portion is
considered.  Set to undef to just get the offset.
=cut

sub lon {
  my $self = shift;
  my $lon = shift;

  if (defined $lon) {
    if ($lon =~ /^-?\d+(?:\.\d+)?$/ and $lon > -180 and $lon < 180) {
      $self->{_lon} = $lon ne "-0" ? int($lon) : "-0";
      $self->_update();
    } else {
      croak "Invalid longitude ($lon)!";
    }
  }

  return undef unless defined $self->{_dlat} and defined $self->{_dlon};

  return $self->{_lon} eq "-0" || $self->{_lon} < 0 ? 
                     $self->{_lon} - $self->{_dlon} : 
                     $self->{_lon} + $self->{_dlon};
}

=head2 date

Set or get the date used for the calculation.  Note that this is the actual
date of the meetup in question, even when the 30w rule is in effect.
=cut

sub date {
  my $self = shift;
  my $date = shift;

  if (defined $date) {
    if ($date =~ /^\d\d\d\d-\d\d-\d\d$/) {
      $self->{_date} = $date;
      $self->djia(undef);
      $self->_update();
    } else {
      croak "Invalid date ($date)!";
    }
  }

  return $self->{_date};
}

=head2 djia

Set or get the Dow Jones Industrial Average used for the calculation.  If not
set, it will be automatically retrieved depending on the value of
$self->source.  If the data cannot be retrieved, undef will be returned.
=cut

sub djia {
  my $self = shift;
  my $djia = shift;

  if ($djia) {
    if ($djia =~ /^\d+(?:\.\d+)?$/) {
      $self->{_djia} = $djia;
    } else {
      croak "Invalid DJIA ($djia)!";
    }
  } elsif ($self->source) {
    my $date = $self->date;
    if ($self->use_30w_rule) {
      require Time::Local;
      my ($y, $m, $d) = split /-/, $self->date;
      my $time = Time::Local::timelocal(0, 0, 0, $d, $m-1, $y);
      ($d, $m, $y) = (localtime($time - 24*60*60))[3,4,5];
      $m++; $y += 1900;
      $date = sprintf("%04d-%02d-%02d", $y, $m, $d);
    }
    $self->_log("Requesting", $self->source, "->DJIA($date)");
    $self->{_djia} = $self->_get_djia($date);
  } else {
    $self->_log("No source set, can't automatically get DJIA");
    return undef;
  }

  return $self->{_djia};
}

=head2 source

Set the source of the DJIA opening data.  Will load Geo::Hashing::Source::Name
and call get_djia($date).  See Geo::Hashing::Source::Random for a sample.
=cut

sub source {
  my $self = shift;
  my $source = shift;

  if (defined $source) {
    $self->_log("Loading source Geo::Hashing::Source::\u$source");
    eval " require Geo::Hashing::Source::\u$source";

    if ($@) {
      croak "Failed to load Geo::Hashing::Source::\u$source: $@";
    }

    $self->{_source} = $source;
    $self->_update();
  }

  if ($self->{_source}) {
    return "Geo::Hashing::Source::" . ucfirst $self->{_source};
  } else {
    return undef;
  }
}

=head2 use_30w_rule

Set or get the 30w flag.  Will be set automatically if lon is set and is
greater than -30.
=cut

sub use_30w_rule {
  my $self = shift;
  my $w30 = shift;

  if (defined $w30) {
    $self->{_30w} = $w30 ? 1 : 0;
    $self->_update();
  } elsif (defined $self->lon) {
    if ($self->lon > -30) {
      if (not $self->date) {
        $self->{_30w} = 1;
      } else {
        my ($y, $m, $d) = split /-/, $self->date;
        if ($y > 2008) {
          $self->{_30w} = 1;
        } elsif ($y == 2008 and $m > 5) {
          $self->{_30w} = 1;
        } elsif ($y == 2008 and $m == 5 and $d >= 27) {
          $self->{_30w} = 1;
        } else {
          $self->{_30w} = 0;
        }
      }
    } else {
      $self->{_30w} = 0;
    }
  }

  return $self->{_30w};
}

=head2 debug

Enable or disable diagnostic logging
=cut

sub debug {
  my $self = shift;
  my $debug = shift;

  if (defined $debug) {
    $self->{_debug} = $debug ? 1 : 0;
    $self->_log("Debug", $self->{_debug} ? "enabled" : "disabled");
  }

  return $self->{_debug};
}

# private methods
# _update - given all the information in the object, calculate the day's
#           offsets
sub _update {
  my $self = shift;

  my $djia = $self->djia;
  unless (defined $djia) {
    $self->_log("Failed to get DJIA");
    $self->{_dlat} = $self->{_dlon} = undef;
    return undef;
  }

  $self->_log("DJIA for", $self->date, "is $djia");

  my $md5 = md5_hex($self->date . "-" . $djia);
  $self->_log(" - md5(". $self->date ."-$djia)");
  $self->_log(" - md5 = $md5");

  my ($md5lat, $md5lon) = (substr($md5, 0, 16), substr($md5, 16, 16));
  $self->_log(" -     = $md5lat, $md5lon");
  ($self->{_dlat}, $self->{_dlon}) = (0, 0);

  while (length $md5lat) {
    $self->{_dlat} += hex substr($md5lat, -1, 1, "");
    $self->{_dlon} += hex substr($md5lon, -1, 1, "");
    $self->{_dlat} /= 16;
    $self->{_dlon} /= 16;
  }

  $self->_log(" dlat, dlon => $self->{_dlat}, $self->{_dlon}");
}

# _log - print out a timestampped log entry
sub _log {
  my $self = shift;

  return unless $self->debug;

  print scalar localtime, " - @_\n";
}

# _get_djia - call get_djia on from the current source
sub _get_djia {
  my $self = shift;

  $self->_log("getting DJIA from", $self->source);
  return $self->source->get_djia(@_);
}

=head1 SEE ALSO

Original comic: http://www.xkcd.com/426/

Wiki: http://wiki.xkcd.com/geohashing/Main_Page

IRC: irc://irc.xkcd.com/geohashing

=head1 AUTHOR

Dan Boger, E<lt>zigdon@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Dan Boger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;


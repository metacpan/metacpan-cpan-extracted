package Geo::Coder::Canada::Error;

use strict;

our $VERSION = '0.01';

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  return $self;
}

sub code {
  my $self = shift;
  $self->{code} = $_[0] if $_[0];
  return $self->{code};
}

sub description {
  my $self = shift;
  $self->{description} = $_[0] if $_[0];
  return $self->{description};
}

sub stno {
  my $self = shift;
  $self->{stno} = $_[0] if $_[0];
  return $self->{stno};
}

sub addresst {
  my $self = shift;
  $self->{addresst} = $_[0] if $_[0];
  return $self->{addresst};
}

sub city {
  my $self = shift;
  $self->{city} = $_[0] if $_[0];
  return $self->{city};
}

sub prov {
  my $self = shift;
  $self->{prov} = $_[0] if $_[0];
  return $self->{prov};
}

1;
__END__
Geo::Coder::Canada::Error - Perl extension which holds the results when a geocoder.ca resquest produces an error.

=head1 SYNOPSIS

  use Geo::Coder::Canada;
  my $g = Geo::Coder::Canada->new;
  $g->city('X');
  $g->postal('invalid postal code');
  unless($g->goecode) {
    # Get the Error object...
    my $error = $g->error;
    my $error_msg  = $error->description;
    my $error_code = $error->code;
    my $suggested_street = $error->addresst;
  }

=head1 DESCRIPTION

This method is available from Geo::Coder::Canada::error when the original geocoder.ca request returns an error.

=head1 ATTRIBUTES

=over 4

=item code()

Returns an integer code representing the error.

=item description()

Return an error message string.

=item stno

Returns the suggested street number.

=item addresst

Returns the suggested street name.

=item city

Returns the suggested city name.

=item prov

Returns the suggested province name.

=head1 AUTHOR

Jeff Anderson <jeff@pvrcanada.com>

Copyright (c) 2006 Jeff Anderson. All rights reserved. This program is free sofware; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Geo::Coder::Canada

=cut

package Geo::H3::Base;
use strict;
use warnings;
use Geo::H3::FFI 0.07;

our $VERSION = '0.09';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::H3::Base - H3 Geospatial Hexagon Indexing System Base Object

=head1 SYNOPSIS

In Package

  use base qw{Geo::H3::Base};

In Code

  my $gh3 = Geo::H3->new;
  
=head1 DESCRIPTION

H3 Geospatial Hexagon Indexing System Base Object provides new and ffi methods to children objects.

=head1 CONSTRUCTOR

=head2 new

  my $obj = Package::New->new(key=>$value, ...);

=cut

sub new {
  my $this  = shift;
  my $class = ref($this) ? ref($this) : $this;
  my $self  = {@_};
  bless $self, $class;
  return $self;
}

=head1 OBJECT ACCESSORS

=head2 ffi

Returns a L<Geo::H3::FFI> object

=cut

sub ffi {
  my $self       = shift;
  $self->{'ffi'} = Geo::H3::FFI->new unless $self->{'ffi'};
  return $self->{'ffi'};
}

=head1 SEE ALSO

L<Geo::H3>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

=cut

1;

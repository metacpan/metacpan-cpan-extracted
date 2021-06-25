package Geo::H3::Base;
use strict;
use warnings;
use Geo::H3::FFI;

our $VERSION = '0.06';
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

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

package Geo::GoogleEarth::Pluggable::StyleBase;
use base qw{Geo::GoogleEarth::Pluggable::Base};
use warnings;
use strict;

our $VERSION='0.09';
our $PACKAGE=__PACKAGE__;

=head1 NAME

Geo::GoogleEarth::Pluggable::StyleBase - Geo::GoogleEarth::Pluggable StyleBase Object

=head1 SYNOPSIS

  use base qw{Geo::GoogleEarth::Pluggable::StyleBase};

=head1 DESCRIPTION

Geo::GoogleEarth::Pluggable::StyleBase is a L<Geo::GoogleEarth::Pluggable::Base> with a few other methods.

=head1 USAGE

  my $style=$document->Style(id=>"Style_Internal_HREF",
                             iconHref=>"http://.../path/image.png");

=head1 METHODS

=head2 id

=cut

sub id {
  my $self=shift();
  $self->{'id'}=shift if @_;
  $self->{'id'}=$self->document->nextId($self->type) unless defined $self->{"id"};
  return $self->{'id'};
}

=head2 url

=cut

sub url {
  my $self=shift;
  return sprintf("#%s", $self->id);
}

=head1 BUGS

Please log on RT and send to the geo-perl email list.

=head1 SUPPORT

Try geo-perl email list.

=head1 AUTHOR

  Michael R. Davis (mrdvt92)
  CPAN ID: MRDVT

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::GoogleEarth::Pluggable> creates a GoogleEarth Document.

=cut

1;

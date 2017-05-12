package Geo::WebService::OpenCellID::Response::measure::add;
use warnings;
use strict;
use base qw{Geo::WebService::OpenCellID::Response::measure};
our $VERSION = '0.05';

=head1 NAME

Geo::WebService::OpenCellID::Response::measure::add - Perl API for the opencellid.org database

=head1 SYNOPSIS

=head1 DESCRIPTION

Perl Interface to the database at http://www.opencellid.org/

=head1 USAGE

=head1 METHODS

=head2 id

=cut

sub id {
  my $self=shift;
  return $self->{"data"}->{"id"};
}

=head2 cellid

=cut

sub cellid {
  my $self=shift;
  return $self->{"data"}->{"cellid"};
}

=head2 res

=cut

sub res {
  my $self=shift;
  return $self->{"data"}->{"res"}->[0];
}

=head1 BUGS

Submit to RT and email the Author

=head1 SUPPORT

Try the Author or Try 8motions.com

=head1 AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    STOP, LLC
    domain=>michaelrdavis,tld=>com,account=>perl
    http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;

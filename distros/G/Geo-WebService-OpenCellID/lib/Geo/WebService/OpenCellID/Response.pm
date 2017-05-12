package Geo::WebService::OpenCellID::Response;
use base qw{Geo::WebService::OpenCellID::Base};
use warnings;
use strict;
our $VERSION = '0.04';

=head1 NAME

Geo::WebService::OpenCellID::Response - Perl API for the opencellid.org database

=head1 SYNOPSIS

  use base qw{Geo::WebService::OpenCellID::Response};

=head1 DESCRIPTION

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

=cut

=head1 METHODS

=head2 stat

Returns the status from rsp->stat in the xml

=cut

sub stat {
  my $self=shift;
  return $self->{"data"}->{"stat"};
}

=head2 content

Returns the entire XML document.

=cut

sub content {
  my $self=shift;
  return $self->{"content"};
}

=head2 url

Returns the url of the web service as called

=cut

sub url {
  my $self=shift;
  return $self->{"url"};
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

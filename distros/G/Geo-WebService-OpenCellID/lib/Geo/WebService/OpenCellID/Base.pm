package Geo::WebService::OpenCellID::Base;
use warnings;
use strict;
our $VERSION = '0.03';

=head1 NAME

Geo::WebService::OpenCellID::Base - Perl API for the opencellid.org database

=head1 SYNOPSIS

  use base qw{Geo::WebService::OpenCellID::Base};

=head1 DESCRIPTION

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

sub initialize {
  my $self = shift();
  %$self=@_;
}

=head1 METHODS

=head2 parent

=cut

sub parent {
  my $self=shift;
  return $self->{"parent"};
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

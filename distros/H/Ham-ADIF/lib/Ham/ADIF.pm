# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-04-28 23:35:11 +0100 (Sun, 28 Apr 2013) $
# Id:            $Id: ADIF.pm 160 2013-04-28 22:35:11Z rmp $
# $HeadURL: svn+ssh://psyphi.net/repository/svn/iotamarathon/trunk/lib/Ham/ADIF.pm $
#
package Ham::ADIF;
use strict;
use warnings;
use Carp;
use Ham::ADIF::ADX;
use Ham::ADIF::ADI;

our $VERSION = q[1.5.1];

sub new {
  my ($class, $ref) = @_;
  my $self = { $ref ? %{$ref} : () };

  bless $self, $class;

  return $self;
}

sub parse_adi {
  my ($self, $filename, $schema) = @_;
  return Ham::ADIF::ADI->new->parse_file($filename);
}

sub parse_adx {
  my ($self, $filename, $schema) = @_;
  return Ham::ADIF::ADX->new->parse_file($filename, $schema);
}

sub parse_file {
  my ($self, $filename, $schema) = @_;

  if($schema ||
    $filename =~ /xml$/smix ||
    $filename =~ /adx$/smix) {
    return $self->parse_adx($filename, $schema);
  }

  #########
  # determine if we have ADI or ADX
  #
  my $io        = IO::File->new($filename, q[r]);
  my $firstline = <$io>;
  if($firstline =~ m{<[?]xml}smix) {
    return $self->parse_adx($filename, $schema);
  }

  return $self->parse_adi($filename);
}

1;
__END__

=head1 NAME

Ham::ADIF

=head1 VERSION

$LastChangedRevision: 160 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new

=head2 parse_adi

=head2 parse_adx

=head2 parse_file

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Carp

=item Ham::ADIF::ADX

=item Ham::ADIF::ADI

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

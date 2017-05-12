# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-04-28 23:35:11 +0100 (Sun, 28 Apr 2013) $
# Id:            $Id: ADX.pm 160 2013-04-28 22:35:11Z rmp $
# $HeadURL: svn+ssh://psyphi.net/repository/svn/iotamarathon/trunk/lib/Ham/ADIF/ADX.pm $
#
package Ham::ADIF::ADX;
use strict;
use warnings;
use XML::LibXML;
use Carp;
use base qw(Ham::ADIF);

our $VERSION = do { my ($r) = q$Revision: 160 $ =~ /(\d+)/smx; $r; };

sub parse_file {
  my ($self, $filename, $schema) = @_;

  my $doc = XML::LibXML->new->parse_file($filename);

  if($schema) {
    my $xmlschema = XML::LibXML::Schema->new( location => $schema );
    eval {
      $xmlschema->validate( $doc );
    } or do {
      # nothing / fail validation
    };
  }

  #########
  # capture custom user-defined fields
  #
  my @userdefs_in = $doc->findnodes('/ADX/HEADER/USERDEF');
  my $userdefs    = [map { q[] . $_->to_literal } @userdefs_in];

  #########
  # capture data records
  #
  my @recs_in = $doc->findnodes('/ADX/RECORDS/RECORD');
  my $recs    = [];
  for my $rec_in (@recs_in) {
    my $rec = {};

    #########
    # standard fields
    #
    for my $field (qw(QSO_DATE TIME_ON CALL BAND FREQ MODE IOTA IOTA_ISLAND_ID DXCC)) {
      $rec->{lc $field} = q[] . $rec_in->findnodes("./$field")->to_literal;
    }

    #########
    # user-defined fields
    #
    for my $field (@{$userdefs}) {
      my $filter = sprintf q[USERDEF[@FIELDNAME="%s"]], $field;
      $rec->{lc $field} = q[] . $rec_in->findnodes("./$filter")->to_literal;
    }

    push @{$recs}, $rec;
  }

  return $recs;
}

1;
__END__

=head1 NAME

Ham::ADIF::ADX

=head1 VERSION

$LastChangedRevision: 160 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new

=head2 parse_file

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item XML::LibXML

=item Carp

=item base

=item Ham::ADIF

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

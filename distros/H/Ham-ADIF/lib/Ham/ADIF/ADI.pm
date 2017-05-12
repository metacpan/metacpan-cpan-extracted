# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-12-26 22:25:17 +0000 (Thu, 26 Dec 2013) $
# Id:            $Id: ADI.pm 344 2013-12-26 22:25:17Z rmp $
# $HeadURL: svn+ssh://psyphi.net/repository/svn/iotamarathon/trunk/lib/Ham/ADIF/ADI.pm $
#
package Ham::ADIF::ADI;
use strict;
use warnings;
use XML::LibXML;
use Carp;
use base qw(Ham::ADIF);
use IO::File;
use English qw(-no_match_vars);

our $VERSION = do { my ($r) = q$Revision: 344 $ =~ /(\d+)/smx; $r; };

sub parse_file {
  my ($self, $filename) = @_;

  my $io = IO::File->new($filename, q[r]);

  #########
  # thank goodness ADI is case-insensitive and we're spared using sensible things like record separators
  #
  my $header      = q[];
  my $read_header = 1;
  my $rec         = q[];
  my $recs        = [];

  while(my $line = <$io>) {
    if($line =~ m{<EOR>}) {
      #########
      # JA1NLX - ADI with no header
      #
      $read_header = 0;
    }

    if($read_header) {
      $header .= $line;
    } else {
      $rec .= $line;
    }

    if($line =~ m{<EOH>}smix) {
      $self->_process_header($header);
      $read_header = 0;

    } elsif($line =~ m{<EOR>}smix) {
      push @{$recs}, $self->_process_record($rec);
      $rec = q[];
    }
  }

  return $recs;
}

sub _process_record {
  my ($self, $rec) = @_;

  my $struct = {};
  for my $tag (split m{[\r\n<]+}smx, $rec) {
    if(!$tag) {
      next;
    }

    my ($tagname, $length, $type, $value) = $tag =~ m{(.*?):(\d+)(:D)?>(.*?)\s*$}smix;
    if(!$tagname) {
      next;
    }

    $struct->{lc $tagname} = $value;
  }

  return $struct;
}

sub _process_header {
  my ($self, $header) = @_;

  my $struct = {};
  for my $tag (split m{[\r\n]+}smx, $header) {
    if(!$tag) {
      next;
    }

    my ($tagname, $length, $datatype, $value, $enum) = $tag =~ m{<(.*?):(\d+)(?::(.*?))?>(.*?)(?:,{(.*?)})?$}smix;
    if(!$tagname) {
      next;
    }

    $struct->{lc $tagname} = $value;
  }

  return $struct;
}

1;

__END__

=head1 NAME

Ham::ADIF::ADI

=head1 VERSION

$LastChangedRevision: 344 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

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

=item IO::File

=item English

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

# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-11-25 22:31:26 +0000 (Mon, 25 Nov 2013) $
# Id:            $Id: DXCC.pm 271 2013-11-25 22:31:26Z rmp $
# $HeadURL: svn+ssh://psyphi.net/repository/svn/iotamarathon/trunk/lib/Ham/DXCC.pm $
#
# built from clublog cty.xml
#
package Ham::DXCC;
use strict;
use warnings;
use XML::XPath;
use LWP::Simple;
use Carp;

our $APIKEY  = q[];
our $SOURCE  = q[https://secure.clublog.org/cty.php?api=%s];
our $VERSION = q[1.2];

sub new {
  my ($class) = @_;
  my $self    = {};

  bless $self, $class;
  return $self;
}

sub fetch {
  my ($self, $filename) = @_;
  my $apikey = $self->{apikey} || $APIKEY || $ENV{DXCC_APIKEY};

  if(!$apikey) {
    croak q[You need to specify an api key in obj->{apikey}, Ham::DXCC::APIKEY or ENV{APIKEY}];
  }

  my $source = sprintf $SOURCE, $apikey;

  getstore($SOURCE, "$filename.gz");
  system qw(gzip -fd), "$filename.gz";
  return 1;
}

sub parse {
  my ($self, $filename, $schema) = @_;

  if($self->{parse}) {
    return $self->{parse};
  }

  my $doc     = XML::XPath->new(filename => $filename);
  my $results = {};

  my $SECTIONS = {
                  '/clublog/exceptions/exception'           => [qw(call entity adif cqz ituz cont long lat start end)],
                  '/clublog/prefixes/prefix'                => [qw(call entity adif cqz ituz cont long lat start end)],
                  '/clublog/invalid_operations/invalid'     => [qw(call start end)],
                  '/clublog/zone_exceptions/zone_exception' => [qw(call start end zone)],
                 };

  for my $section (keys %{$SECTIONS}) {
    my $things_in  = [$doc->find($section)->get_nodelist];
    my $things_out = [];

    for my $in (@{$things_in}) {
      my $out = {};

      #########
      # standard fields
      #
      my $rec = $in->getAttribute('record');
      $out->{record} = $rec;
      for my $field (@{$SECTIONS->{$section}}) {
        my $val = $doc->find("./$field", $in)->string_value;
        if(!$val) {
          next;
        }
        $out->{lc $field} = $val;
      }

      push @{$things_out}, $out;
    }

    my ($root) = $section =~ m{^/clublog/(\S+)/}smx;
    $results->{$root} = $things_out;
  }

  $self->{parse} = $results;
  return $results;
}

1;

__END__

=head1 NAME

Ham::DXCC

=head1 VERSION

$LastChangedRevision: 271 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new

=head2 fetch

=head2 parse

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

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

# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-04-28 23:35:11 +0100 (Sun, 28 Apr 2013) $
# Id:            $Id: IOTA.pm 160 2013-04-28 22:35:11Z rmp $
# $HeadURL$
#
# http://www.rsgbiota.org/xml/fulllist.xml
#
package Ham::IOTA;
use strict;
use warnings;
use XML::XPath;
use LWP::Simple;
use Carp;

our $SOURCE  = "http://www.rsgbiota.org/xml/fulllist.xml";
our $VERSION = '1.2';

sub new {
  my ($class) = @_;
  my $self    = {};

  bless $self, $class;
  return $self;
}

sub fetch {
  my ($self, $filename) = @_;
  getstore($SOURCE, $filename);
  return 1;
}

sub parse {
  my ($self, $filename, $schema) = @_;

  if($self->{parse}) {
    return $self->{parse};
  }

  my $doc     = XML::XPath->new(filename => $filename);
  my $results = [];

  my $groups = [$doc->find(q[/iotaxml/body/groupInfo])->get_nodelist];

  for my $group (@{$groups}) {
    my $out         = {
		       islands => [],
		      };

    $out->{grpref}  = $group->find(q[./grpRef])->string_value;
    $out->{grpname} = $group->find(q[./grpName])->string_value;
    my $islands     = [$group->find(q[./grpContent/island])->get_nodelist];

    my $dxcc = [$group->find(q[./dxcc])->get_nodelist]->[0];
    $out->{dxcc_id}   = $dxcc->getAttribute('id');
    $out->{dxcc_name} = $dxcc->string_value;

    for my $island (@{$islands}) {
      my $id   = $island->getAttribute('id');
      my $name = $island->string_value;
      push @{$out->{islands}}, {
				id   => $id,
				name => $name,
			       };
    }
    push @{$results}, $out;
  }

  $self->{parse} = $results;
  return $results;
}

1;

__END__

=head1 NAME

Ham::DXCC

=head1 VERSION

$LastChangedRevision: 160 $

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

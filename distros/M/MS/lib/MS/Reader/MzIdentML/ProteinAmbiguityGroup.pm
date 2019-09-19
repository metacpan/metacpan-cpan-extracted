package MS::Reader::MzIdentML::ProteinAmbiguityGroup;

use strict;
use warnings;

use parent qw/MS::Reader::XML::Record::CV/;

sub _pre_load {

    my ($self) = @_;
    $self->{_toplevel} = 'ProteinAmbiguityGroup';

    # Lookup tables to quickly check elements
    $self->{_make_named_array} = {
        cvParam   => 'accession',
        userParam => 'name',
    };

    $self->{_make_named_hash} = { map {$_ => 'id'} qw/
        ProteinDetectionHypothesis
    / };

    $self->{_make_anon_array} = { map {$_ => 1} qw/
        PeptideHypothesis
        SpectrumIdentificationList
    / };

}

sub id         { return $_[0]->{id}         } 
sub name       { return $_[0]->{name}       }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzIdentML::ProteinAmbiguityGroup - mzIdentML protein group object

=head1 SYNOPSIS

    while (my $grp = $search->next_protein_group) {
        
        # $grp is an MS::Reader::MzIdentML::ProteinAmbiguityGroup object

    }

=head1 DESCRIPTION

C<MS::Reader::MzIdentML::ProteinAmbiguityGroup> is a class representing an
mzIdentML protein group.

=head1 INHERITANCE

C<MS::Reader::MzIdentML::ProteinAmbiguityGroup> is a subclass of
L<MS::Reader::XML::Record::CV>, which in turn inherits from
L<MS::Reader::XML::Record>, and inherits the methods of these parental
classes. Please see the documentation for those classes for details of
available methods not detailed below.

=head1 METHODS

=head2 id

=head2 name

    my $id   = $grp->id;
    my $name = $grp->name;

Return the ID and name of the group, respectively.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

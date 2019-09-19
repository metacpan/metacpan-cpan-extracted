package MS::Reader::ProtXML::Group;

use strict;
use warnings;

use parent qw/MS::Reader::XML::Record/;

sub _pre_load {

    my ($self) = @_;

    $self->{_toplevel} = 'protein_group';

    $self->{_make_named_hash} = { map {$_ => 'name'} qw/
        parameter
    / };

    $self->{_make_anon_array} = { map {$_ => 1} qw/
        protein
        analysis_result
        indistinguishable_protein
        peptide
        modification_info
        mod_aminoacid_mass
        peptide_parent_protein
        indistinguishable_peptide
    / };

}

1;


__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::ProtXML::Group - A protXML protein group

=head1 SYNOPSIS

    use MS::Reader::ProtXML;

    my $res = MS::Reader::ProtXML->new('res.prot.xml');

    while (my $grp = $res->next_group) {

        # $res is a MS::Reader::ProtXML::Group object

    }

=head1 DESCRIPTION

C<MS::Reader::ProtXML::Group> is a class representing a protXML protein group.

=head1 INHERITANCE

C<MS::Reader::ProtXML::Group> is a subclass of L<MS::Reader::XML::Record>, which in turn
inherits from L<MS::Reader>, and inherits the methods of these parental
classes. Please see the documentation for those classes for details of
available methods not detailed below.

=head1 METHODS

C<MS::Reader::ProtXML::Group> does not implement any methods beyond those of
its parental classes.

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

package MS::Reader::MzIdentML::SequenceItem;

use strict;
use warnings;

use base qw/MS::Reader::XML::Record::CV/;


sub _pre_load {

    my ($self) = @_;

    # Lookup tables to quickly check elements
    $self->{_make_named_array} = {
        cvParam   => 'accession',
        userParam => 'name',
    };

    $self->{_make_anon_array} = { map {$_ => 1} qw/
        Modification
        SubstitutionModification
    / };

}

# Here we need to set the toplevel in the _post_load() function, since the
# class is not known until now.
sub _post_load {

    my ($self) = @_;

    for (qw/DBSequence Peptide PeptideEvidence/) {
        if (defined $self->{$_}) {
            bless $self => "MS::Reader::MzIdentML::$_";
            $self->{_toplevel} = $_;
            $self->SUPER::_post_load();
            return;
        }
    }
    die "Unexpected root element, unable to assign class\n";

}

sub id         { return $_[0]->{id}                 } 

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzIdentML::SequenceItem - base class for SequenceCollection
children

=head1 SYNOPSIS

    package MS::Reader::MzIdentML::Foo;

    use parent qw/MS::Reader::MzIdentML::SequenceItem;

=head1 DESCRIPTION

C<MS::Reader::MzIdentML::SequenceItem> is a base class for children of the
<SequenceCollection> element. It does not correspond to an actual XML element,
but is necessary because multiple types of elements are found as direct
children of <SequenceCollection>, and a base class is needed to represent all
of these.

=head1 METHODS

=head2 id

    my $id   = $seq->id;

Return the ID of the item

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

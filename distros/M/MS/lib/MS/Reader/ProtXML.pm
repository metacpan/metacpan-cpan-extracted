package MS::Reader::ProtXML;

use strict;
use warnings;

use parent qw/MS::Reader::XML/;

use Carp;

use MS::Reader::ProtXML::Group;

our $VERSION = 0.003;

sub _pre_load {

    my ($self) = @_;

    # ---------------------------------------------------------------------------#
    # These tables are the main configuration point between the parser and the
    # specific document schema. For more information, see the documentation
    # for the parent class MS::Reader::XML
    # ---------------------------------------------------------------------------#

    $self->{_toplevel} = 'protein_summary';

    $self->{__record_classes} = {
        protein_group => 'MS::Reader::ProtXML::Group',
    };

    $self->{_skip_inside} = { map {$_ => 1} qw/
        protein_group
    / };

    $self->{_make_index} = { map {$_ => 'group_number'} qw/
        protein_group
    / };

    $self->{_make_named_array} = {
        userParam => 'name',
    };

    $self->{_make_named_hash} = {
        parameter => 'name'
    };

    $self->{_make_anon_array} = { map {$_ => 1} qw/
        analysis_summary
        nsp_distribution
        ni_distribution
        protein_summary_data_filter
    / };

}

sub next_group {

    my ($self) = @_;
    return $self->next_record($self);


}


sub fetch_group {

    my ($self, $idx) = @_;

    return $self->fetch_record($self => $idx);

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::ProtXML - A simple but complete protXML parser

=head1 SYNOPSIS

    use MS::Reader::ProtXML;

    my $res = MS::Reader::ProtXML->new('res.prot.xml');

    while (my $grp = $res->next_group) {

        # $res is a MS::Reader::ProtXML::Group object

    }

=head1 DESCRIPTION

C<MS::Reader::ProtXML> is a parser for the protXML format for storing protein
identification in mass spectrometry.



=head1 INHERITANCE

C<MS::Reader::ProtXML> is a subclass of L<MS::Reader::XML>, which in turn
inherits from L<MS::Reader>, and inherits the methods of these parental
classes. Please see the documentation for those classes for details of
available methods not detailed below.

=head1 METHODS

=head2 new

    my $res = MS::Reader::ProtXML->new( $fn,
        use_cache => 0,
        paranoid  => 0,
    );

Takes an input filename (required) and optional argument hash and returns an
C<MS::Reader::ProtXML> object. This constructor is inherited directly from
L<MS::Reader>. Available options include:

=over

=item * use_cache — cache fetched records in memory for repeat access
(default: FALSE)

=item * paranoid — when loading index from disk, recalculates MD5 checksum
each time to make sure raw file hasn't changed. This adds (typically) a few
seconds to load times. By default, only file size and mtime are checked.

=back

=head2 next_group

    while (my $grp = $res->next_group) {
        # do something
    }

Returns an C<MS::Reader::ProtXML::Group> object representing the next protein
group in the file, or C<undef> if the end of records has been reached.
Typically used to iterate over each group in the run.

=head2 fetch_group

    my $grp = $res->fetch_group($idx);

Takes a single argument (zero-based group index) and returns an
C<MS::Reader::ProtXML::Group> object representing the protein group at that
index.  Throws an exception if the index is out of range.

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

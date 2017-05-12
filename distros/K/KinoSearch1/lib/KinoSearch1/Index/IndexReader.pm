package KinoSearch1::Index::IndexReader;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        invindex       => undef,
        seg_infos      => undef,
        close_invindex => 1,
        invindex_owner => 1,
    );
    __PACKAGE__->ready_get(qw( invindex ));
}

use KinoSearch1::Store::FSInvIndex;
use KinoSearch1::Index::SegReader;
use KinoSearch1::Index::MultiReader;
use KinoSearch1::Index::SegInfos;
use KinoSearch1::Index::IndexFileNames qw(
    WRITE_LOCK_NAME  WRITE_LOCK_TIMEOUT
    COMMIT_LOCK_NAME COMMIT_LOCK_TIMEOUT
);

sub new {
    my $temp = shift->SUPER::new(@_);
    return $temp->_open_multi_or_segreader;
}

# Returns a subclass of IndexReader: either a MultiReader or a SegReader,
# depending on whether an invindex contains more than one segment.
sub _open_multi_or_segreader {
    my $self = shift;

    # confirm an InvIndex object or make one using a supplied filepath.
    if ( !a_isa_b( $self->{invindex}, 'KinoSearch1::Store::InvIndex' ) ) {
        $self->{invindex} = KinoSearch1::Store::FSInvIndex->new(
            path => $self->{invindex} );
    }
    my $invindex = $self->{invindex};

    # read the segments file and decide what to do
    my $reader;
    $invindex->run_while_locked(
        lock_name => COMMIT_LOCK_NAME,
        timeout   => COMMIT_LOCK_TIMEOUT,
        do_body   => sub {
            my $seg_infos = KinoSearch1::Index::SegInfos->new;
            $seg_infos->read_infos($invindex);

            # create a SegReader for each segment in the invindex
            my @seg_readers;
            for my $sinfo ( $seg_infos->infos ) {
                push @seg_readers,
                    KinoSearch1::Index::SegReader->new(
                    seg_name => $sinfo->get_seg_name,
                    invindex => $invindex,
                    );
            }
            # if there's one SegReader use it; otherwise make a MultiReader
            $reader
                = @seg_readers == 1
                ? $seg_readers[0]
                : KinoSearch1::Index::MultiReader->new(
                invindex    => $invindex,
                sub_readers => \@seg_readers,
                );
        },
    );

    return $reader;
}

=begin comment

    my $num = $reader->max_doc;

Return the highest document number available to the reader.

=end comment
=cut

sub max_doc { shift->abstract_death }

=begin comment

    my $num = $reader->num_docs;

Return the number of (non-deleted) documents available to the reader.

=end comment
=cut

sub num_docs { shift->abstract_death }

=begin comment

    my $term_docs = $reader->term_docs($term);

Given a Term, return a TermDocs subclass.

=end comment
=cut

sub term_docs { shift->abstract_death }

=begin comment

    my $norms_reader = $reader->norms_reader($field_name);

Given a field name, return a NormsReader object.

=end comment
=cut

sub norms_reader { shift->abstract_death }

=begin comment

    $reader->delete_docs_by_term( $term );

Delete all the documents available to the reader that index the given Term.

=end comment
=cut

sub delete_docs_by_term { shift->abstract_death }

=begin comment

    $boolean = $reader->has_deletions

Return true if any documents have been marked as deleted.

=end comment
=cut

sub has_deletions { shift->abstract_death }

=begin comment

    my $enum = $reader->terms($term);

Given a Term, return a TermEnum subclass.  The Enum will be be pre-located via
$enum->seek($term) to the right spot.

=end comment
=cut

sub terms { shift->abstract_death }

=begin comment

    my $field_names = $reader->get_field_names(
        indexed => $indexed_fields_only,
    );

Return a hashref which is a list of field names.  If the parameter 'indexed'
is true, return only the names of fields which are indexed.

=end comment
=cut

sub get_field_names { shift->abstract_death }

=begin comment

    my $infos = $reader->generate_field_infos;

Return a new FieldInfos object, describing all the fields held by the reader.
The FieldInfos object will be consolidated, and thus may not be representative
of every field in every segment if there are conflicting definitions.

=end comment
=cut

sub generate_field_infos { shift->abstract_death }

=begin comment

    my @sparse_segreaders = $reader->segreaders_to_merge;
    my @all_segreaders    = $reader->segreaders_to_merge('all');

Find segments which are good candidates for merging, as they don't contain
many valid documents.  Returns an array of SegReaders.  If passed an argument,
return all SegReaders.

=end comment
=cut

sub segreaders_to_merge { shift->abstract_death }

=begin comment

    $reader->close;

Release all resources.

=end comment
=cut

sub close { shift->abstract_death }

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Index::IndexReader - base class for objects which read invindexes

==head1 DESCRIPTION

There are two subclasses of the abstract base class IndexReader: SegReader,
which reads a single segment, and MultiReader, which condenses the output of
several SegReaders.  Since each segment is a self-contained inverted index, a
SegReader is in effect a complete index reader.  

The constructor for IndexReader returns either a SegReader if the index has
only one segment, or a MultiReader if there are multiple segments.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

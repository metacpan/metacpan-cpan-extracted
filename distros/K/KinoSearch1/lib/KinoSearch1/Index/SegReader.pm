package KinoSearch1::Index::SegReader;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Index::IndexReader );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # params/members
        invindex => undef,
        seg_name => undef,

        # members
        comp_file_reader => undef,
        tinfos_reader    => undef,
        finfos           => undef,
        fields_reader    => undef,
        freq_stream      => undef,
        prox_stream      => undef,
        deldocs          => undef,
        norms_readers    => undef,
    );

    __PACKAGE__->ready_get(
        qw(
            finfos
            fields_reader
            freq_stream
            prox_stream
            deldocs
            seg_name
            )
    );
}

use KinoSearch1::Index::CompoundFileReader;
use KinoSearch1::Index::TermInfosReader;
use KinoSearch1::Index::FieldsReader;
use KinoSearch1::Index::FieldInfos;
use KinoSearch1::Index::NormsReader;
use KinoSearch1::Index::SegTermDocs;
use KinoSearch1::Index::DelDocs;

# use KinoSearch1::Util::Class's new()
# Note: can't inherit IndexReader's new() without recursion problems
*new = *KinoSearch1::Util::Class::new;

sub init_instance {
    my $self = shift;
    my ( $seg_name, $invindex ) = @{$self}{ 'seg_name', 'invindex' };
    $self->{norms_readers} = {};

    # initialize DelDocs
    $self->{deldocs} = KinoSearch1::Index::DelDocs->new(
        invindex => $invindex,
        seg_name => $seg_name,
    );
    $self->{deldocs}->read_deldocs( $invindex, "$seg_name.del" )
        if ( $invindex->file_exists("$seg_name.del") );

    # initialize a CompoundFileReader
    my $comp_file_reader = $self->{comp_file_reader}
        = KinoSearch1::Index::CompoundFileReader->new(
        invindex => $invindex,
        seg_name => $seg_name,
        );

    # initialize FieldInfos
    my $finfos = $self->{finfos} = KinoSearch1::Index::FieldInfos->new;
    $finfos->read_infos( $comp_file_reader->open_instream("$seg_name.fnm") );

    # initialize FieldsReader
    $self->{fields_reader} = KinoSearch1::Index::FieldsReader->new(
        finfos        => $finfos,
        fdata_stream  => $comp_file_reader->open_instream("$seg_name.fdt"),
        findex_stream => $comp_file_reader->open_instream("$seg_name.fdx"),
    );

    # initialize TermInfosReader
    $self->{tinfos_reader} = KinoSearch1::Index::TermInfosReader->new(
        invindex => $comp_file_reader,
        seg_name => $seg_name,
        finfos   => $finfos,
    );

    # open the frequency data, the positional data, and the norms
    $self->{freq_stream} = $comp_file_reader->open_instream("$seg_name.frq");
    $self->{prox_stream} = $comp_file_reader->open_instream("$seg_name.prx");
    $self->_open_norms;
}

sub max_doc { shift->{fields_reader}->get_size }

sub num_docs {
    my $self = shift;
    return $self->max_doc - $self->{deldocs}->get_num_deletions;
}

sub delete_docs_by_term {
    my ( $self, $term ) = @_;
    my $term_docs = $self->term_docs($term);
    $self->{deldocs}->delete_by_term_docs($term_docs);
}

sub commit_deletions {
    my $self = shift;
    return unless $self->{deldocs}->get_num_deletions;
    my $filename = $self->{seg_name} . ".del";
    $self->{deldocs}
        ->write_deldocs( $self->{invindex}, $filename, $self->max_doc );
}

sub has_deletions { shift->{deldocs}->get_num_deletions }

sub _open_norms {
    my $self = shift;
    my ( $seg_name, $finfos, $comp_file_reader )
        = @{$self}{ 'seg_name', 'finfos', 'comp_file_reader' };
    my $max_doc = $self->max_doc;

    # create a NormsReader for each indexed field.
    for my $finfo ( $finfos->get_infos ) {
        next unless $finfo->get_indexed;
        my $filename = "$seg_name.f" . $finfo->get_field_num;
        my $instream = $comp_file_reader->open_instream($filename);
        $self->{norms_readers}{ $finfo->get_name }
            = KinoSearch1::Index::NormsReader->new(
            instream => $instream,
            max_doc  => $max_doc,
            );
    }
}

sub terms {
    my ( $self, $term ) = @_;
    return $self->{tinfos_reader}->terms($term);
}

sub fetch_term_info {
    my ( $self, $term ) = @_;
    return $self->{tinfos_reader}->fetch_term_info($term);
}

sub get_skip_interval {
    shift->{tinfos_reader}->get_skip_interval;
}

sub doc_freq {
    my ( $self, $term ) = @_;
    my $tinfo = $self->{tinfos_reader}->fetch_term_info($term);
    return defined $tinfo ? $tinfo->get_doc_freq : 0;
}

sub term_docs {
    my ( $self, $term ) = @_;
    my $term_docs = KinoSearch1::Index::SegTermDocs->new( reader => $self, );
    $term_docs->seek($term);
    return $term_docs;
}

sub norms_reader {
    my ( $self, $field_name ) = @_;
    return unless exists $self->{norms_readers}{$field_name};
    return $self->{norms_readers}{$field_name};
}

sub get_field_names {
    my ( $self, %args ) = @_;
    my @fields = $self->{finfos}->get_infos;
    @fields = grep { $_->get_indexed } @fields
        if $args{indexed};
    my @names = map { $_->get_name } @fields;
    return \@names;
}

sub generate_field_infos {
    my $self       = shift;
    my $new_finfos = $self->{finfos}->clone;
    $new_finfos->set_from_file(0);
    return $new_finfos;
}

sub fetch_doc {
    $_[0]->{fields_reader}->fetch_doc( $_[1] );
}

sub segreaders_to_merge {
    my ( $self, $all ) = @_;
    return $self if $all;
    return;
}

sub close {
    my $self = shift;
    return unless $self->{close_invindex};

    $self->{deldocs}->close;
    $self->{finfos}->close;
    $self->{fields_reader}->close;
    $self->{tinfos_reader}->close;
    $self->{comp_file_reader}->close;
    $self->{freq_stream}->close;
    $self->{prox_stream}->close;
    $_->close for values %{ $self->{norms_readers} };
}
1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Index::SegReader - read from a single-segment invindex

==head1 DESCRIPTION

Single-segment implementation of IndexReader.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut


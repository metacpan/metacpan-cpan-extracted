package KinoSearch1::Index::MultiReader;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Index::IndexReader );

BEGIN {
    __PACKAGE__->init_instance_vars(
        invindex    => undef,
        sub_readers => undef,
        starts      => undef,
        max_doc     => 0,
        norms_cache => undef,
    );
}

use KinoSearch1::Index::FieldInfos;
use KinoSearch1::Index::SegReader;
use KinoSearch1::Index::MultiTermDocs;

# use KinoSearch1::Util::Class's new()
# Note: can't inherit IndexReader's new() without recursion problems
*new = *KinoSearch1::Util::Class::new;

sub init_instance {
    my $self = shift;
    $self->{sub_readers} ||= [];
    $self->{starts}      ||= [];
    $self->{norms_cache} ||= {};

    $self->_init_sub_readers;
}

sub _init_sub_readers {
    my $self = shift;
    my @starts;
    my $max_doc = 0;
    for my $sub_reader ( @{ $self->{sub_readers} } ) {
        push @starts, $max_doc;
        $max_doc += $sub_reader->max_doc;
    }
    $self->{starts}  = \@starts;
    $self->{max_doc} = $max_doc;
}

sub max_doc { shift->{max_doc} }

sub num_docs {
    my $self = shift;

    my $num_docs = 0;
    $num_docs += $_->num_docs for @{ $self->{sub_readers} };

    return $num_docs;
}

sub term_docs {
    my ( $self, $term ) = @_;

    my $term_docs = KinoSearch1::Index::MultiTermDocs->new(
        sub_readers => $self->{sub_readers},
        starts      => $self->{starts},
    );
    $term_docs->seek($term);
    return $term_docs;
}

sub doc_freq {
    my ( $self, $term ) = @_;
    my $doc_freq = 0;
    $doc_freq += $_->doc_freq($term) for @{ $self->{sub_readers} };
    return $doc_freq;
}

sub fetch_doc {
    my ( $self, $doc_num ) = @_;
    my $reader_index = $self->_reader_index($doc_num);
    $doc_num -= $self->{starts}[$reader_index];
    return $self->{sub_readers}[$reader_index]->fetch_doc($doc_num);
}

sub delete_docs_by_term {
    my ( $self, $term ) = @_;
    $_->delete_docs_by_term($term) for @{ $self->{sub_readers} };
}

sub commit_deletions {
    my $self = shift;
    $_->commit_deletions for @{ $self->{sub_readers} };
}

# Determine which sub-reader a document resides in
sub _reader_index {
    my ( $self, $doc_num ) = @_;
    my $starts = $self->{starts};
    my ( $lo, $mid, $hi ) = ( 0, undef, $#$starts );
    while ( $hi >= $lo ) {
        $mid = ( $lo + $hi ) >> 1;
        my $mid_start = $starts->[$mid];
        if ( $doc_num < $mid_start ) {
            $hi = $mid - 1;
        }
        elsif ( $doc_num > $mid_start ) {
            $lo = $mid + 1;
        }
        else {
            while ( $mid < $#$starts and $starts->[ $mid + 1 ] == $mid_start )
            {
                $mid++;
            }
            return $mid;
        }

    }
    return $hi;
}

sub norms_reader {
    # TODO refactor and minimize copying
    my ( $self, $field_num ) = @_;
    if ( exists $self->{norms_cache}{$field_num} ) {
        return $self->{norms_cache}{$field_num};
    }
    else {
        my $bytes = '';
        for my $seg_reader ( @{ $self->{sub_readers} } ) {
            my $seg_norms_reader = $seg_reader->norms_reader($field_num);
            $bytes .= ${ $seg_norms_reader->get_bytes } if $seg_norms_reader;
        }
        my $norms_reader = $self->{norms_cache}{$field_num}
            = KinoSearch1::Index::NormsReader->new(
            bytes   => $bytes,
            max_doc => $self->max_doc,
            );
        return $norms_reader;
    }
}

sub generate_field_infos {
    my $self       = shift;
    my $new_finfos = KinoSearch1::Index::FieldInfos->new;
    my @sub_finfos
        = map { $_->generate_field_infos } @{ $self->{sub_readers} };
    $new_finfos->consolidate(@sub_finfos);
    return $new_finfos;
}

sub get_field_names {
    my $self = shift;
    my %field_names;
    for my $sub_reader ( @{ $self->{sub_readers} } ) {
        my $sub_field_names = $sub_reader->get_field_names;
        @field_names{@$sub_field_names} = (1) x scalar @$sub_field_names;
    }
    return [ keys %field_names ];
}

sub segreaders_to_merge {
    my ( $self, $all ) = @_;
    return unless @{ $self->{sub_readers} };
    return @{ $self->{sub_readers} } if $all;

    # sort by ascending size in docs
    my @sorted_sub_readers
        = sort { $a->num_docs <=> $b->num_docs } @{ $self->{sub_readers} };

    # find sparsely populated segments
    my $total_docs = 0;
    my $threshold  = -1;
    for my $i ( 0 .. $#sorted_sub_readers ) {
        $total_docs += $sorted_sub_readers[$i]->num_docs;
        if ( $total_docs < fibonacci( $i + 5 ) ) {
            $threshold = $i;
        }
    }

    # if any of the segments are sparse, return their readers
    if ( $threshold > -1 ) {
        return @sorted_sub_readers[ 0 .. $threshold ];
    }
    else {
        return;
    }
}

# Generate fibonacci series
my %fibo_cache;

sub fibonacci {
    my $n = shift;
    return $fibo_cache{$n} if exists $fibo_cache{$n};
    my $result = $n < 2 ? $n : fibonacci( $n - 1 ) + fibonacci( $n - 2 );
    $fibo_cache{$n} = $result;
    return $result;
}

sub close {
    my $self = shift;
    return unless $self->{close_invindex};
    $_->close for @{ $self->{sub_readers} };
}

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Index::MultiReader - read from a multi-segment invindex

==head1 DESCRIPTION 

Multi-segment implementation of IndexReader.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

package KinoSearch1::Index::DelDocs;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::BitVector );

use KinoSearch1::Util::IntMap;

# instance vars:
my %num_deletions;

sub new {
    my $self = shift->SUPER::new;
    $num_deletions{"$self"} = 0;
    return $self;
}

# Read a deletions file if one exists.
sub read_deldocs {
    my ( $self, $invindex, $filename ) = @_;

    # load the file into memory if it's there
    if ( $invindex->file_exists($filename) ) {
        my $instream = $invindex->open_instream($filename);
        my $byte_size;
        ( $byte_size, $num_deletions{"$self"} ) = $instream->lu_read('ii');
        $self->set_bits( $instream->lu_read("a$byte_size") );
        $instream->close;
    }
}

# Blast out a hard copy of the deletions held in memory.
sub write_deldocs {
    my ( $self, $invindex, $filename, $max_doc ) = @_;
    if ( $invindex->file_exists($filename) ) {
        $invindex->delete_file($filename);
    }
    my $outstream = $invindex->open_outstream($filename);

    # pad out deldocs->bits
    $self->set_capacity($max_doc);

    # write header followed by deletions data
    my $byte_size = ceil( $max_doc / 8 );
    $outstream->lu_write(
        "iia$byte_size",         $byte_size,
        $num_deletions{"$self"}, $self->get_bits,
    );

    $outstream->close;
}

# Mark a doc as deleted.
sub set {
    my ( $self, $doc_num ) = @_;
    # ... only if it isn't already deleted
    if ( !$self->get($doc_num) ) {
        $self->SUPER::set($doc_num);
        $num_deletions{"$self"}++;
    }
}

# Delete all the docs represented by a TermDocs object.
sub delete_by_term_docs {
    my ( $self, $term_docs ) = @_;
    $num_deletions{"$self"} += _delete_by_term_docs( $self, $term_docs );
}

# Undelete a doc.
sub clear {
    my ( $self, $doc_num ) = @_;
    # ... only if it was deleted before
    if ( $self->get($doc_num) ) {
        $self->SUPER::clear($doc_num);
        $num_deletions{"$self"}--;
    }
}

sub get_num_deletions { $num_deletions{"$_[0]"} }

# Map around deleted documents.
sub generate_doc_map {
    my ( $self, $max, $offset ) = @_;
    my $map = $self->_generate_doc_map( $max, $offset );
    return KinoSearch1::Util::IntMap->new($map);
}

# If these get implemented, we'll need to write a range_count(first, last)
# method for BitVector.
sub bulk_set   { shift->todo_death }
sub bulk_clear { shift->todo_death }

sub close { }

sub DESTROY {
    my $self = shift;
    delete $num_deletions{"$self"};
    $self->SUPER::DESTROY;
}

1;

__END__

__XS__

MODULE = KinoSearch1 PACKAGE = KinoSearch1::Index::DelDocs

SV* 
_generate_doc_map(deldocs, max, offset);
    BitVector *deldocs;
    I32        max;
    I32        offset;
PREINIT:
    SV *map_sv;
CODE:
    map_sv = Kino1_DelDocs_generate_doc_map(deldocs, max, offset);
    RETVAL = newRV_noinc(map_sv);
OUTPUT: RETVAL

I32
_delete_by_term_docs(deldocs, term_docs)
    BitVector *deldocs;
    TermDocs  *term_docs;
CODE:
    RETVAL = Kino1_DelDocs_delete_by_term_docs(deldocs, term_docs);
OUTPUT: RETVAL

__H__

#ifndef H_KINOSEARCH_DELDOCS
#define H_KINOSEARCH_DELDOCS 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1IndexTermDocs.h"
#include "KinoSearch1UtilBitVector.h"

SV* Kino1_DelDocs_generate_doc_map(BitVector*, I32, I32);
I32 Kino1_DelDocs_delete_by_term_docs(BitVector*, TermDocs*);


#endif /* include guard */

__C__

#include "KinoSearch1IndexDelDocs.h"

SV*
Kino1_DelDocs_generate_doc_map(BitVector *deldocs, I32 max, I32 offset) {
    SV   *doc_map_sv;
    I32  *doc_map;
    I32   new_doc_num;
    int   i;

    /* allocate space for the doc map */
    doc_map_sv = newSV(max * sizeof(I32) + 1);
    SvCUR_set(doc_map_sv, max * sizeof(I32));
    SvPOK_on(doc_map_sv);
    doc_map = (I32*)SvPVX(doc_map_sv);

    /* -1 for a deleted doc, a new number otherwise */
    new_doc_num = 0;
    for (i = 0; i < max; i++) {
        if (Kino1_BitVec_get(deldocs, i))
            *doc_map++ = -1;
        else
            *doc_map++ = offset + new_doc_num++;
    }
    
    return doc_map_sv;
}

I32  
Kino1_DelDocs_delete_by_term_docs(BitVector* deldocs, TermDocs* term_docs) {
    I32 doc;
    I32 num_deleted = 0;

    /* iterate through term docs, marking each doc returned as deleted */
    while (term_docs->next(term_docs)) {
        doc = term_docs->get_doc(term_docs);
        if (Kino1_BitVec_get(deldocs, doc))
            continue;
        Kino1_BitVec_set(deldocs, doc);
        num_deleted++;
    }
    return num_deleted;
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Index::DelDocs - manage documents deleted from an invindex

==head1 DESCRIPTION

DelDocs provides the low-level mechanisms for declaring a document deleted
from a segment, and for finding out whether or not a particular document has
been deleted.

Note that documents are not actually gone from the invindex until the segment
gets rewritten.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

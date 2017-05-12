package KinoSearch1::Document::Field;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor args / members
        name       => undef,
        analyzer   => undef,
        boost      => 1,
        stored     => 1,
        indexed    => 1,
        analyzed   => 1,
        vectorized => 1,
        binary     => 0,
        compressed => 0,
        omit_norms => 0,
        field_num  => undef,
        value      => '',
        fnm_bits   => undef,
        fdt_bits   => undef,
        tv_string  => '',
        tv_cache   => undef,
    );
    __PACKAGE__->ready_get_set(
        qw(
            value
            tv_string
            boost
            indexed
            stored
            analyzed
            vectorized
            binary
            compressed
            analyzer
            field_num
            name
            omit_norms
            )
    );
}

use KinoSearch1::Index::FieldsReader;
use KinoSearch1::Index::FieldInfos;
use KinoSearch1::Index::TermVector;

use Storable qw( dclone );

sub init_instance {
    my $self = shift;

    # field name is required
    croak("Missing required parameter 'name'")
        unless length $self->{name};

    # don't index binary fields
    if ( $self->{binary} ) {
        $self->{indexed}  = 0;
        $self->{analyzed} = 0;
    }
}

sub clone {
    my $self = shift;
    return dclone($self);
}

# Given two Field objects, return a child which has all the positive
# attributes of both parents (meaning: values are OR'd).
sub breed_with {
    my ( $self, $other ) = @_;
    my $kid = $self->clone;
    for (qw( indexed vectorized )) {
        $kid->{$_} ||= $other->{$_};
    }
    return $kid;
}

sub set_fnm_bits { $_[0]->{fnm_bits} = $_[1] }

sub get_fnm_bits {
    my $self = shift;
    $self->{fnm_bits} = KinoSearch1::Index::FieldInfos->encode_fnm_bits($self)
        unless defined $self->{fnm_bits};
    return $self->{fnm_bits};
}

sub set_fdt_bits { $_[0]->{fdt_bits} = $_[1] }

sub get_fdt_bits {
    my $self = shift;
    $self->{fdt_bits}
        = KinoSearch1::Index::FieldsReader->encode_fdt_bits($self)
        unless defined $self->{fdt_bits};
    return $self->{fdt_bits};
}

sub get_value_len { bytes::length( $_[0]->{value} ) }

# Return a TermVector object for a given Term, if it's in this field.
sub term_vector {
    my ( $self, $term_text ) = @_;
    return unless bytes::length( $self->{tv_string} );
    if ( !defined $self->{tv_cache} ) {
        $self->{tv_cache} = _extract_tv_cache( $self->{tv_string} );
    }
    if ( exists $self->{tv_cache}{$term_text} ) {
        my ( $positions, $starts, $ends )
            = _unpack_posdata( $self->{tv_cache}{$term_text} );
        my $term_vector = KinoSearch1::Index::TermVector->new(
            text          => $term_text,
            field         => $self->{name},
            positions     => $positions,
            start_offsets => $starts,
            end_offsets   => $ends,
        );
        return $term_vector;
    }

    return;
}

1;

__END__

__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Document::Field

=for comment

Return ref to a hash where the keys are term texts and the values are encoded
positional data.

=cut

void
_extract_tv_cache(tv_string_sv)
    SV *tv_string_sv;
PREINIT:
    HV *tv_cache_hv;
PPCODE:
    tv_cache_hv = Kino1_Field_extract_tv_cache(tv_string_sv);
    XPUSHs( sv_2mortal( newRV_noinc( (SV*)tv_cache_hv ) ) );
    XSRETURN(1);

=for comment

Decompress positional data.

=cut

void
_unpack_posdata(posdata_sv)
    SV *posdata_sv;
PREINIT:
    AV     *positions_av, *starts_av, *ends_av;
PPCODE:
    positions_av = newAV();
    starts_av    = newAV();
    ends_av      = newAV();
    Kino1_Field_unpack_posdata(posdata_sv, positions_av, starts_av, ends_av);
    XPUSHs(sv_2mortal( newRV_noinc((SV*)positions_av) ));
    XPUSHs(sv_2mortal( newRV_noinc((SV*)starts_av)    ));
    XPUSHs(sv_2mortal( newRV_noinc((SV*)ends_av)      ));
    XSRETURN(3);


__H__

#ifndef H_KINOSEARCH_FIELD
#define H_KINOSEARCH_FIELD 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1StoreInStream.h"
#include "KinoSearch1UtilCarp.h"

HV*  Kino1_Field_extract_tv_cache(SV*);
void Kino1_Field_unpack_posdata(SV*, AV*, AV*, AV*);

#endif /* include guard */

__C__

#include "KinoSearch1DocumentField.h"

HV* 
Kino1_Field_extract_tv_cache(SV *tv_string_sv) {
    HV *tv_cache_hv;
    char    *tv_string, *bookmark_ptr, *key;
    char   **tv_ptr;
    STRLEN   len, tv_len, overlap, key_len;
    SV      *text_sv, *nums_sv;
    I32      i, num_terms, num_positions;

    /* allocate a new hash */
    tv_cache_hv = newHV();
    
    /* extract pointers */
    tv_string = SvPV(tv_string_sv, tv_len);
    tv_ptr    = &tv_string;

    /* create a base text scalar */
    text_sv = newSV(1);
    SvPOK_on(text_sv);
    *(SvEND(text_sv)) = '\0';

    /* read the number of vectorized terms in the field */
    num_terms = Kino1_InStream_decode_vint(tv_ptr);
    for (i = 0; i < num_terms; i++) {

        /* decompress the term text */
        overlap = Kino1_InStream_decode_vint(tv_ptr);
        SvCUR_set(text_sv, overlap);
        len = Kino1_InStream_decode_vint(tv_ptr);
        sv_catpvn(text_sv, *tv_ptr, len);
        *tv_ptr += len;
        key = SvPV(text_sv, key_len);

        /* get positions & offsets string */
        num_positions = Kino1_InStream_decode_vint(tv_ptr);
        bookmark_ptr = *tv_ptr;
        while(num_positions--) {
            /* leave nums compressed to save a little mem */
            (void)Kino1_InStream_decode_vint(tv_ptr);
            (void)Kino1_InStream_decode_vint(tv_ptr);
            (void)Kino1_InStream_decode_vint(tv_ptr);
        }
        len = *tv_ptr - bookmark_ptr;
        nums_sv = newSVpvn(bookmark_ptr, len);

        /* store the $text => $posdata pair in the output hash */
        hv_store(tv_cache_hv, key, key_len, nums_sv, 0);
    }
    SvREFCNT_dec(text_sv);

    return tv_cache_hv;
}

void
Kino1_Field_unpack_posdata(SV *posdata_sv, AV *positions_av, 
                          AV *starts_av,  AV *ends_av) {
    STRLEN  len;
    char   *posdata, *posdata_end;
    char  **posdata_ptr;
    SV     *num_sv;
    posdata      = SvPV(posdata_sv, len);
    posdata_ptr  = &posdata;
    posdata_end  = SvEND(posdata_sv);

    /* translate encoded VInts to Perl scalars */
    while(*posdata_ptr < posdata_end) {
        num_sv = newSViv( Kino1_InStream_decode_vint(posdata_ptr) );
        av_push(positions_av, num_sv);
        num_sv = newSViv( Kino1_InStream_decode_vint(posdata_ptr) );
        av_push(starts_av,    num_sv);
        num_sv = newSViv( Kino1_InStream_decode_vint(posdata_ptr) );
        av_push(ends_av,      num_sv);
    }

    if (*posdata_ptr != posdata_end)
        Kino1_confess("Bad encoding of posdata");
}

__POD__

=head1 NAME

KinoSearch1::Document::Field - a field within a document

=head1 SYNOPSIS

    # no public interface

=head1 DESCRIPTION

Fields can only be defined or manipulated indirectly, via InvIndexer and Doc.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut



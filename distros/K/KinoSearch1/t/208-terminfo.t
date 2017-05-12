#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 18;

BEGIN { use_ok('KinoSearch1::Index::TermInfo'); }

my $tinfo = KinoSearch1::Index::TermInfo->new( 10, 20, 30, 40, 50 );

my $cloned_tinfo = $tinfo->clone;
isnt(
    0 + $tinfo,
    0 + $cloned_tinfo,
    "the clone should be a separate C struct"
);

is( $tinfo->get_doc_freq,      10, "new sets doc_freq correctly" );
is( $tinfo->get_doc_freq,      10, "... doc_freq cloned" );
is( $tinfo->get_frq_fileptr,   20, "new sets frq_fileptr correctly" );
is( $tinfo->get_frq_fileptr,   20, "... frq_fileptr cloned" );
is( $tinfo->get_prx_fileptr,   30, "new sets prx_fileptr correctly" );
is( $tinfo->get_prx_fileptr,   30, "... prx_fileptr cloned" );
is( $tinfo->get_skip_offset,   40, "new sets skip_offset correctly" );
is( $tinfo->get_skip_offset,   40, "... skip_offset cloned" );
is( $tinfo->get_index_fileptr, 50, "new sets index_fileptr correctly" );
is( $tinfo->get_index_fileptr, 50, "... index_fileptr cloned" );

$tinfo->set_doc_freq(5);
is( $tinfo->get_doc_freq,        5,  "set/get doc_freq" );
is( $cloned_tinfo->get_doc_freq, 10, "setting orig doesn't affect clone" );

$tinfo->set_frq_fileptr(15);
is( $tinfo->get_frq_fileptr, 15, "set/get frq_fileptr" );

$tinfo->set_prx_fileptr(25);
is( $tinfo->get_prx_fileptr, 25, "set/get prx_fileptr" );

$tinfo->set_skip_offset(35);
is( $tinfo->get_skip_offset, 35, "set/get skip_offset" );

$tinfo->set_index_fileptr(45);
is( $tinfo->get_index_fileptr, 45, "set/get index_fileptr" );

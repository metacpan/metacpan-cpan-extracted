#!/usr/bin/perl

use strict;
use warnings;
use JCAMP::DX;
use JCAMP::DX::LabelDataRecord;

use Test::More tests => 3;
use Test::Warn;

my $simple_ldr = JCAMP::DX::LabelDataRecord->new( 'record', 'value' );

my $block = JCAMP::DX->new( 'test block' );
$block->push_LDR( $simple_ldr );

warning_is {
    $block->push_LDR( $simple_ldr );
} "duplicate values for label 'RECORD' were found, will not overwrite";

my $similar_ldr = JCAMP::DX::LabelDataRecord->new( 're co-rd', 'value' );

warning_is {
    $block->push_LDR( $similar_ldr );
} "duplicate values for label 'RECORD' were found, will not overwrite";

is( $block->to_string,
    <<'END' );
##TITLE=test block
##record=value
##END=
END

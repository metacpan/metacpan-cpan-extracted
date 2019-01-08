#!/usr/bin/perl

use strict;
use warnings;
use JCAMP::DX;
use JCAMP::DX::LabelDataRecord;

use Test::More tests => 6;

my $simple_ldr = JCAMP::DX::LabelDataRecord->new( 'record', 'value' );
is( $simple_ldr->to_string, "##record=value\n" );

my $ASDF_ldr = JCAMP::DX::LabelDataRecord->new( 'xydata', <<'END' );
(X++(Y..Y))
1 1 2 3 4 5
6 6
END
is( $ASDF_ldr->to_string,
    "##xydata=(XY..XY)\n1,1 2,2 3,3 4,4 5,5 6,6 \n" );

my $XY_ldr = JCAMP::DX::LabelDataRecord->new( 'xypoints', <<'END' );
(XY..XY)
1,1 2,2;3,3
4,4 5,5 6,6 7,7 8,8 9,9 10,10 11,11 12,12 13,13 14,14 15,15 16,16 17,17
END
is( $XY_ldr->to_string, <<'END' );
##xypoints=(XY..XY)
1,1 2,2 3,3 4,4 5,5 6,6 7,7 8,8 9,9 10,10 11,11 12,12 13,13 14,14 15,15 16,16 
17,17 
END

my $XYW_ldr = JCAMP::DX::LabelDataRecord->new( 'xypoints', <<'END' );
(XYW..XYW)
1,1,1;2,2,2
3,3,3
END
is( $XYW_ldr->to_string, <<'END' );
##xypoints=(XYW..XYW)
1,1,1 2,2,2 3,3,3 
END

my $block = JCAMP::DX->new( 'test block' );
$block->push_LDR( $simple_ldr );
$block->push_LDR( $ASDF_ldr );
is( $block->to_string,
    <<'END' );
##TITLE=test block
##record=value
##xydata=(XY..XY)
1,1 2,2 3,3 4,4 5,5 6,6 
##END=
END

my $unordered_block = JCAMP::DX->new();
$unordered_block->push_LDR( $simple_ldr );
$unordered_block->push_LDR( JCAMP::DX::LabelDataRecord->new( 'JCAMP-DX', 4.24 ) );
$unordered_block->push_LDR( JCAMP::DX::LabelDataRecord->new( 'TITLE', 'test block' ) );
$unordered_block->order_labels;
is( $unordered_block->to_string,
    <<'END' );
##TITLE=test block
##JCAMP-DX=4.24
##record=value
##END=
END

#!/usr/bin/perl

use strict;
use Test::More tests => 33;
use File::Temp qw/ tempdir /;
use Games::SGF::Tournament;

my @sgf = (<<SFG0);
(;GM[1]FF[3]
RU[Japanese]SZ[9]HA[0]KM[5.5]
PW[Alpha]
PB[Bravo]
GN[Alpha (W) vs. Bravo (B)]
DT[2005-08-10]
SY[Cgoban 1.9.14]TM[30:00]
RE[B+75.5]
;B[cc]BL[1793];W[gg]WL[1772];B[cg]BL[1790];W[gc]WL[1770];B[tt]BL[1787]
;W[tt]WL[1770];
TB[aa][ba][ca][da][ea][fa][ga][ha][ia][ab][bb][cb][db][eb][fb][gb][hb][ib][ac][bc][dc][ec][fc][gc][hc][ic][ad][bd][cd][dd][ed][fd][gd][hd][id][ae][be][ce][de][ee][fe][ge][he][ie][af][bf][cf][df][ef][ff][gf][hf][if][ag][bg][dg][eg][fg][gg][hg][ig][ah][bh][ch][dh][eh][fh][gh][hh][ih][ai][bi][ci][di][ei][fi][gi][hi][ii]
C[The game is over.  Final score:
   White = 0 territory + 0 captures + 5.5 komi = 5.5
   Black = 79 territory + 2 captures = 81
Black wins by 75.5.
]
)
SFG0

my $tempdir = tempdir( TMPDIR => 1, CLEANUP => 1 );
my $i = 0;
foreach (@sgf) {
    open FH, ">$tempdir/game$i.sgf";
    print FH $_;
    close FH;
    $i++;
}

my $base_url = '/~joe/';
my $t = Games::SGF::Tournament->new( sgf_dir => $tempdir, base_url => $base_url );
isa_ok($t, 'Games::SGF::Tournament', 'tournament object');
can_ok($t, qw/ games scores /);

SKIP: {
    eval 'use HTML::TreeBuilder';
    skip 'HTML::TreeBuilder required for testing output', 31 if $@;
    
    my($table, $anchor, $field, $record);
    
    $table = HTML::TreeBuilder->new_from_content($t->games())->guts();
    is($table->tag(), 'table', 'games table @0');
    
    $record = ($table->content_list())[2];
    is($record->tag(), 'tr', 'record @0.0');
    
    $field = ($record->content_list())[0];
    is($field->tag(), 'td', 'field @0.0.0');
    
    $anchor = ($field->content_list())[0];
    is($anchor->tag(), 'a', 'anchor @0.0.0');
    is($anchor->attr('href'), "${base_url}game0.sgf", 'href @0.0.0');
    is(($anchor->content_list())[0], '1', 'game number @0.0.0');
    
    text_field($record, '0.0.1', 'Bravo', 'black');
    text_field($record, '0.0.2', 'Alpha', 'white');
    text_field($record, '0.0.3', 'Japanese/9/0/5.5/30:00', 'setup');
    text_field($record, '0.0.4', '2005-08-10', 'date');
    text_field($record, '0.0.5', 'B+75.5', 'result');
    
    $table = HTML::TreeBuilder->new_from_content($t->scores())->guts();
    is($table->tag(), 'table', 'scores table @1');
    
    $record = ($table->content_list())[2];
    is($record->tag(), 'tr', 'record @1.0');
    
    text_field($record, '1.0.0', '1', 'position');
    text_field($record, '1.0.1', 'Bravo', 'name');
    text_field($record, '1.0.2', '1', 'score');
    
    $record = ($table->content_list())[3];
    is($record->tag(), 'tr', 'record @1.1');
    
    text_field($record, '1.1.0', '2', 'position');
    text_field($record, '1.1.1', 'Alpha', 'name');
    text_field($record, '1.1.2', '0', 'score');
}

sub text_field {
    my $record = shift;
    my $matrix = shift;
    my $expect = shift;
    my $descr  = shift;
    $matrix =~ /.*\.(.*)/;
    my $field = ($record->content_list())[$1];
    is($field->tag(), 'td', "field \@$matrix");
    is(($field->content_list())[0], $expect, "$descr \@$matrix");
}
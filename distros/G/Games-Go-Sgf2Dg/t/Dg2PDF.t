#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Go-Dg2PDF.t'

#########################

use strict;
use IO::File;
use Test::More;
eval { require PDF::Create };
if ($@) {
    plan(skip_all => "PDF::Create not installed: $@");
}

plan (tests => 6);

use_ok('Games::Go::Sgf2Dg::Dg2PDF');
use_ok('Games::Go::Sgf2Dg::Diagram');


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $diagram;
eval { $diagram = Games::Go::Sgf2Dg::Diagram->new(
                    hoshi             => ['ba', 'cd'],
                    black             => ['ab'],
                    white             => ['dd', 'cd'],
                    callback          => \&conflictCallback,
                    enable_overstones => 1,
                    overstone_eq_mark => 1); };
die "Can't create diagram: $@" if $@;

my $dg2pdf;

##
## create dg2pdf object:
##
eval { $dg2pdf = Games::Go::Sgf2Dg::Dg2PDF->new(
        doubleDigits => 0,
        coords       => 1,
        file         => '>test.pdf'); };
is( $@, '',                                     'new Dg2PDF object'  );
isa_ok( $dg2pdf, 'Games::Go::Sgf2Dg::Dg2PDF',           '   dg2pdf is the right class'  );

$dg2pdf->configure(boardSizeX => 5, boardSizeY => 5);
$dg2pdf->convertDiagram($diagram);
eval {$dg2pdf->comment(' comment')};
is( $@, '',                                     'added comment' );
$dg2pdf->comment(' and more comment');
is( $@, '',                                     'raw print' );

# since we rely on PDF::Create (which could change), we don't want
# to make our tests too specific.  But if the other converters pass,
# this one should be OK (unless PDF::Create has problems, of
# course).

##
## end of tests
##

__END__


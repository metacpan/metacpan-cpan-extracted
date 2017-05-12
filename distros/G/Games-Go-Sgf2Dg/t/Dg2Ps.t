#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Go-Dg2Ps.t'

#########################

use strict;
use IO::File;
use Test::More;
eval { require PostScript::File };
if ($@) {
    plan(skip_all => "PostScript::File not installed: $@");
}

plan (tests => 8);

use_ok('Games::Go::Sgf2Dg::Dg2Ps');
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

my $dg2ps;

##
## create dg2ps object:
##
eval { $dg2ps = Games::Go::Sgf2Dg::Dg2Ps->new(
        coords       => 1,
        file         => '>test.ps'); };
is( $@, '',                                     'new Dg2Ps object'  );
isa_ok( $dg2ps, 'Games::Go::Sgf2Dg::Dg2Ps',           '   dg2ps is the right class'  );

$dg2ps->configure(boardSizeX => 5, boardSizeY => 5);
$dg2ps->convertDiagram($diagram);
eval {$dg2ps->comment(' comment')};
is( $@, '',                                     'added comment' );
$dg2ps->comment(' and more comment');
is( $@, '',                                     'raw print' );

# since we rely on PostScript::File (which could change), we don't want
# to make our tests too specific.  But if the other converters pass,
# this one should be OK

my $ps = $dg2ps->close;
like($ps, qr/My_Functions/,                     'has a My_Functions' );
like($ps, qr/showpage/,                         'has a showpage' );
##
## end of tests
##

__END__



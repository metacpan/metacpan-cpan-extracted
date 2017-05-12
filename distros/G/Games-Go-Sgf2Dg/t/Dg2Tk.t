#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Go-Dg2Tk.t'

#########################

use strict;
use IO::File;
use Test::More;
eval { require Tk };
if ($@) {
    plan(skip_all => "Tk not installed: $@");
}

eval { require Tk::Canvas };
if ($@) {
    plan(skip_all => "Canvas not found: $@");
}


plan (tests => 6);

use_ok('Games::Go::Sgf2Dg::Dg2Tk');
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

my $dg2tk;

##
## create dg2tk object:
##
SKIP: {
    eval { $dg2tk = Games::Go::Sgf2Dg::Dg2Tk->new(
            doubleDigits => 0,
            coords       => 1, ); };
    skip ("$@ (no X server?)", 4) if ($@ =~ m/couldn't connect to display/);

    is( $@, '',                                     'new Dg2Tk object'  );
    isa_ok( $dg2tk, 'Games::Go::Sgf2Dg::Dg2Tk',             '   dg2tk is the right class'  );

    $dg2tk->configure(boardSizeX => 5, 
                      boardSizeY => 5,
                      bg        => '#d2b48c');
    $dg2tk->convertDiagram($diagram);
    $dg2tk->{mw}->update;
    $dg2tk->{mw}->after(500);
    eval {$dg2tk->comment(' comment')};
    is( $@, '',                                     'added comment' );
    $dg2tk->comment(' and more comment');
    is( $@, '',                                     'raw print' );
    $dg2tk->{mw}->update;
    $dg2tk->{mw}->after(500);
    $dg2tk->{mw}->destroy;
}

##
## end of tests
##

__END__

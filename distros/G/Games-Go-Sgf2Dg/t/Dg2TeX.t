#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Go-Dg2TeX.t'

#########################

use strict;
use IO::File;
use Test::More tests => 17;

BEGIN {
    use_ok('Games::Go::Sgf2Dg::Dg2TeX');
    use_ok('Games::Go::Sgf2Dg::Diagram');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dg2tex;

##
## create dg2tex object:
##
my ($tex1, $tex);        # collect TeX here
eval { $dg2tex = Games::Go::Sgf2Dg::Dg2TeX->new(
        doubleDigits => 0,
        coords       => 1,
        simple       => 1,
        file         => \$tex1); };
is( $@, '',                                     'new Dg2TeX object' );
isa_ok( $dg2tex, 'Games::Go::Sgf2Dg::Dg2TeX',           '   dg2tex is the right class' );

eval {$dg2tex->comment(' comment')};
is( $@, '',                                     'added comment' );
is( $tex1, "% comment\n",                        '    tex is correct');
$dg2tex->comment(' and more comment');
is( $tex1, "% comment\n% and more comment\n",     'added more comment' );
eval { $dg2tex->configure(
        file => \$tex,); };
is( $@, '',                                     're-configure' );
eval {$dg2tex->print('raw print', "\n")};
is( $@, '',                                     'raw print' );
is( $tex,
'\magnification=1000
% goWhiteInk changes from black to white ink, but it\'s not supported by
%   all output drivers (notably pdftex).  Dg2TeX only uses it for long
%   labels on black stones, so it may not matter...
\def\goWhiteInk#1{\special{color push rgb 1 1 1} {#1} \special{color pop}}%
% goLap is used to overlap a long label on a stone or intersection
\def\goLap#1#2{\setbox0=\hbox{#1} \rlap{#1} \raise 2\goTextAdj\hbox to \wd0{\hss\eightpoint{#2}\hss}}%
% goLapWhite overlaps like goLap, but also changes to white ink for the label
\def\goLapWhite#1#2{\setbox0=\hbox{#1}\rlap{#1}\raise 2\goTextAdj\hbox to \wd0{\hss\eightpoint\goWhiteInk{#2}\hss}}%
% rc places right-hand side coordinates
\def\rc#1{\raise \goTextAdj\hbox to \goIntWd{\kern \goTextAdj\hss\rm#1\hss}}%
% bc places bottom coordinates
\def\bc#1{\hbox to \goIntWd{\hss#1\hss}}%
\lineskip=0pt
\parindent=0pt
\raggedbottom        % allow pages to end short (if next diagram doesn\'t fit)
\input gooemacs
\parindent=0pt
raw print
',                                               'raw print is good' );
$tex = '';
is( $dg2tex->converted,
'% comment
% and more comment
\magnification=1000
% goWhiteInk changes from black to white ink, but it\'s not supported by
%   all output drivers (notably pdftex).  Dg2TeX only uses it for long
%   labels on black stones, so it may not matter...
\def\goWhiteInk#1{\special{color push rgb 1 1 1} {#1} \special{color pop}}%
% goLap is used to overlap a long label on a stone or intersection
\def\goLap#1#2{\setbox0=\hbox{#1} \rlap{#1} \raise 2\goTextAdj\hbox to \wd0{\hss\eightpoint{#2}\hss}}%
% goLapWhite overlaps like goLap, but also changes to white ink for the label
\def\goLapWhite#1#2{\setbox0=\hbox{#1}\rlap{#1}\raise 2\goTextAdj\hbox to \wd0{\hss\eightpoint\goWhiteInk{#2}\hss}}%
% rc places right-hand side coordinates
\def\rc#1{\raise \goTextAdj\hbox to \goIntWd{\kern \goTextAdj\hss\rm#1\hss}}%
% bc places bottom coordinates
\def\bc#1{\hbox to \goIntWd{\hss#1\hss}}%
\lineskip=0pt
\parindent=0pt
\raggedbottom        % allow pages to end short (if next diagram doesn\'t fit)
\input gooemacs
\parindent=0pt
raw print
',                                              'converted TeX is good' );
is( $dg2tex->converted(''), '',                 'converted TeX cleared' );
is( $dg2tex->convertText('this <is> a {TeX} \conversion_test'), 
                         'this $<$is$>$ a $\lbrace$TeX$\rbrace$ $\backslash$conversion\_test',
                                                'text-to-TeX conversion');

my $diagram;
eval { $diagram = Games::Go::Sgf2Dg::Diagram->new(
                    hoshi             => ['ba', 'cd'],
                    black             => ['ab'],
                    white             => ['dd', 'cd'],
                    boardSizeX        => 5,
                    boardSizeY        => 5,
                    callback          => \&conflictCallback,
                    enable_overstones => 1,
                    overstone_eq_mark => 1); };
die "Can't create diagram: $@" if $@;

eval { $dg2tex->configure(boardSizeX => 5, boardSizeY => 5,); };
is( $@, '',                                     'reconfigured Dg2TeX object' );
is( $dg2tex->converted(''), '',                 'converted TeX cleared' );
eval { $dg2tex->convertDiagram( $diagram); };
is( $@, '',                                     'converted Diagram' );
is ($dg2tex->converted,
'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Start of Unknown Diagram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\vbox{\goo
\hbox{\0??<\0??*\0??(\0??(\0??>\rc{5}}
\hbox{\- @[\0??+\0??+\0??+\0??]\rc{4}}
\hbox{\0??[\0??+\0??+\0??+\0??]\rc{3}}
\hbox{\0??[\0??+\- !*\- !+\0??]\rc{2}}
\hbox{\0??,\0??)\0??)\0??)\0??.\rc{1}}
\vskip 4pt
\hbox{\bc A\bc B\bc C\bc D\bc E}\smallskip
\break
}
\nobreak{\bf Unknown Diagram}\hfil\break
\hfil\break


' ,                                             '    TeX is correct' );

##
## end of tests
##

__END__

package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Spelling;
	1;
    } or do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
    Test::Spelling->import();
}

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();

1;
__DATA__
autocopy
combinatorial
CPSearch
cubical
darwin
executables
Fowler's
Guine
filename
Ishigaki
Lite
Kenichi
Kulesha
latin
lib
Mehner
merchantability
Mhz
min
MSWin
Multi
O'Neill
OO
pbcopy
pbpaste
Pegg
quads
quincunx
Samurai
square's
sudoku
sudokug
SudokuTk
sudokux
TkPlayer
topologies
trove
tuple
xclip
webcmd
Wasabi
Wyant
Wyllie
YASudoku

use strict;
use warnings;
use utf8;

use Test::More;
use Test::More::UTF8;

BEGIN {
	plan skip_all => "Author tests not required for installation. Test only run when called with RELEASE_TESTING=1"
		unless $ENV{RELEASE_TESTING};
}

use Test::Spelling;
use Pod::Wordlist;

add_stopwords(<DATA>);

all_pod_files_spelling_ok( qw(lib) );

__DATA__
AFM
AGL
Alessandro
Bbox
DVI
Gorohovski
KPX
PostScript
REase
Replicase
WX
compressibility
customisable
documentclass
eXcept
esc
facultative
fillable
fontdimen
footnotesize
glyphlist
glyphs
glyphtounicode
interword
kerning
minimalistic
noBbox
noKPX
normalsize
nucleotides
num
numL
ofile
outdir
ru
scriptsize
standalones
stopC
tex
th
wxC

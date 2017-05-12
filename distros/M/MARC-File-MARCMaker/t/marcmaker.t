#!perl 

=head1 NAME

marcmaker.t -- Tests for MARC::File::MARCMaker.

=head1 TO DO

Compare decoded and encoded versions of records in camel.mrk and camel.usmarc with each other.

Determine how to link as_marcmaker method from MARC::File::MARCMaker to MARC::Field without "only once" warning.

More comprehensive tests of character encoding/decoding.

=cut

use strict;
use warnings;

use Test::More tests=>10;

BEGIN { use_ok( 'MARC::Batch' ); }
BEGIN { use_ok( 'MARC::File::USMARC' ); }
BEGIN { use_ok( 'MARC::File::MARCMaker' ); }

if (UNIVERSAL::can('MARC::Field', 'as_marcmaker')) {
    warn "MARC::Field now has an as_marcmaker() method";
} 
else {
    no warnings;
    *MARC::Field::as_marcmaker = *MARC::File::MARCMaker::as_marcmaker;
}

###################################################
###################################################

#create MARC::Record object for manipulation
my $record = MARC::Record->new();

isa_ok( $record, 'MARC::Record', 'MARC record' );

$record->leader("00000nam  2200253 a 4500"); 
my $nfields = $record->add_fields(
    #control number so one is present
    ['001', "ttt05000001"
    ],
    #basic 008
    ['008', "050801s2005    ilu           000 0 eng d"
    ],
    #basic 245
    [245, "0","0",
        a => "Test record from text /",
        c => "Bryan Baldus ... [et al.].",
    ],
    [500, '', '',
        a => 'This is a test of ordinary features like replacement of the mnemonics for currency and dollar signs ($) and backslashes (backsolidus \ ) used for blanks in certain areas.'
    ],
    [500, '', '',
        a => 'This is a test for the conversion of curly braces; the opening curly brace ( { ) and the closing curly brace ( } ).'
    ],
    [500, '', '',
        a => "This is a test of diacritics like the uppercase Polish L in ¡âodâz, the uppercase Scandinavia O in ¢st, the uppercase D with crossbar in £uro, the uppercase Icelandic thorn in ¤ann, the uppercase digraph AE in ¥gir, the uppercase digraph OE in ¦uvres, the soft sign in rech§, the middle dot in col¨lecciâo, the musical flat in F©, the patent mark in Frizbeeª, the plus or minus sign in «54%, the uppercase O-hook in B¬, the uppercase U-hook in X­A, the alif in mas®alah, the ayn in °arab, the lowercase Polish l in W±oc±aw, the lowercase Scandinavian o in K²benhavn, the lowercase d with crossbar in ³avola, the lowercase Icelandic thorn in ´ann, the lowercase digraph ae in vµre, the lowercase digraph oe in c¶ur, the lowercase hardsign in s·ezd, the Turkish dotless i in masal¸, the British pound sign in ¹5.95, the lowercase eth in verºur, the lowercase o-hook (with pseudo question mark) in Sà¼, the lowercase u-hook in T½ D½c, the pseudo question mark in càui, the grave accent in tráes, the acute accent in dâesirâee, the circumflex in cãote, the tilde in maänana, the macron in Tåokyo, the breve in russkiæi, the dot above in çzaba, the dieresis (umlaut) in Lèowenbrèau, the caron (hachek) in écrny, the circle above (angstrom) in êarbok, the ligature first and second halves in dëiìadëiìa, the high comma off center in rozdelíovac, the double acute in idîoszaki, the candrabindu (breve with dot above) in Aliïiev, the cedilla in ðca va comme ðca, the right hook in vietña, the dot below in teòda, the double dot below in ököhuótbah, the circle below in Saòmskôrta, the double underscore in õGhulam, the left hook in Lech Wa±÷esa, the right cedilla (comma below) in khøong, the upadhmaniya (half circle below) in ùhumantués, double tilde, first and second halves in únûgalan, high comma (centered) in gþeotermika.",
    ],
    [650, '', '0',
        a => 'MARC records.',
    ],

    );
is( $nfields, 7, "All the fields added OK" );

my @fields500 = $record->field('500');

is($fields500[0]->as_marcmaker(), "=500  \\\\\$aThis is a test of ordinary features like replacement of the mnemonics for currency and dollar signs ({dollar}) and backslashes (backsolidus {bsol} ) used for blanks in certain areas.\n", join "\t", "Dollars and backslashes test ok", $fields500[0]->as_marcmaker());

is($fields500[1]->as_marcmaker(), "=500  \\\\\$aThis is a test for the conversion of curly braces; the opening curly brace ( {lcub} ) and the closing curly brace ( {rcub} ).\n", join "\t", "Curly braces test ok", $fields500[1]->as_marcmaker());

my $rec_as_maker = MARC::File::MARCMaker::encode($record);

my $record_from_maker = MARC::File::MARCMaker::decode($rec_as_maker);

isa_ok( $record_from_maker, 'MARC::Record', 'MARC record from MARCMaker data' );

my @recoded_500s = $record_from_maker->field('500');
print $recoded_500s[0]->as_string(), "\n";

print $recoded_500s[1]->as_string(), "\n";

#######################
### Diacritics test ###
#######################

is ($fields500[2]->as_marcmaker(), "=500  \\\\\$aThis is a test of diacritics like the uppercase Polish L in {Lstrok}{acute}od{acute}z, the uppercase Scandinavia O in {Ostrok}st, the uppercase D with crossbar in {Dstrok}uro, the uppercase Icelandic thorn in {THORN}ann, the uppercase digraph AE in {AElig}gir, the uppercase digraph OE in {OElig}uvres, the soft sign in rech{softsign}, the middle dot in col{middot}lecci{acute}o, the musical flat in F{flat}, the patent mark in Frizbee{reg}, the plus or minus sign in {plusmn}54%, the uppercase O-hook in B{Ohorn}, the uppercase U-hook in X{Uhorn}A, the alif in mas{mlrhring}alah, the ayn in {mllhring}arab, the lowercase Polish l in W{lstrok}oc{lstrok}aw, the lowercase Scandinavian o in K{ostrok}benhavn, the lowercase d with crossbar in {dstrok}avola, the lowercase Icelandic thorn in {thorn}ann, the lowercase digraph ae in v{aelig}re, the lowercase digraph oe in c{oelig}ur, the lowercase hardsign in s{hardsign}ezd, the Turkish dotless i in masal{inodot}, the British pound sign in {pound}5.95, the lowercase eth in ver{eth}ur, the lowercase o-hook (with pseudo question mark) in S{hooka}{ohorn}, the lowercase u-hook in T{uhorn} D{uhorn}c, the pseudo question mark in c{hooka}ui, the grave accent in tr{grave}es, the acute accent in d{acute}esir{acute}ee, the circumflex in c{circ}ote, the tilde in ma{tilde}nana, the macron in T{macr}okyo, the breve in russki{breve}i, the dot above in {dot}zaba, the dieresis (umlaut) in L{uml}owenbr{uml}au, the caron (hachek) in {caron}crny, the circle above (angstrom) in {ring}arbok, the ligature first and second halves in d{llig}i{rlig}ad{llig}i{rlig}a, the high comma off center in rozdel{rcommaa}ovac, the double acute in id{dblac}oszaki, the candrabindu (breve with dot above) in Ali{candra}iev, the cedilla in {cedil}ca va comme {cedil}ca, the right hook in viet{ogon}a, the dot below in te{dotb}da, the double dot below in {under}k{under}hu{dbldotb}tbah, the circle below in Sa{dotb}msk{ringb}rta, the double underscore in {dblunder}Ghulam, the left hook in Lech Wa{lstrok}{commab}esa, the right cedilla (comma below) in kh{rcedil}ong, the upadhmaniya (half circle below) in {breveb}humantu{caron}s, double tilde, first and second halves in {ldbltil}n{rdbltil}galan, high comma (centered) in g{commaa}eotermika.\n", "Diacritics to mnemonics ok.");

is ($recoded_500s[2]->as_string(), "This is a test of diacritics like the uppercase Polish L in ¡âodâz, the uppercase Scandinavia O in ¢st, the uppercase D with crossbar in £uro, the uppercase Icelandic thorn in ¤ann, the uppercase digraph AE in ¥gir, the uppercase digraph OE in ¦uvres, the soft sign in rech§, the middle dot in col¨lecciâo, the musical flat in F©, the patent mark in Frizbeeª, the plus or minus sign in «54%, the uppercase O-hook in B¬, the uppercase U-hook in X­A, the alif in mas®alah, the ayn in °arab, the lowercase Polish l in W±oc±aw, the lowercase Scandinavian o in K²benhavn, the lowercase d with crossbar in ³avola, the lowercase Icelandic thorn in ´ann, the lowercase digraph ae in vµre, the lowercase digraph oe in c¶ur, the lowercase hardsign in s·ezd, the Turkish dotless i in masal¸, the British pound sign in ¹5.95, the lowercase eth in verºur, the lowercase o-hook (with pseudo question mark) in Sà¼, the lowercase u-hook in T½ D½c, the pseudo question mark in càui, the grave accent in tráes, the acute accent in dâesirâee, the circumflex in cãote, the tilde in maänana, the macron in Tåokyo, the breve in russkiæi, the dot above in çzaba, the dieresis (umlaut) in Lèowenbrèau, the caron (hachek) in écrny, the circle above (angstrom) in êarbok, the ligature first and second halves in dëiìadëiìa, the high comma off center in rozdelíovac, the double acute in idîoszaki, the candrabindu (breve with dot above) in Aliïiev, the cedilla in ðca va comme ðca, the right hook in vietña, the dot below in teòda, the double dot below in ököhuótbah, the circle below in Saòmskôrta, the double underscore in õGhulam, the left hook in Lech Wa±÷esa, the right cedilla (comma below) in khøong, the upadhmaniya (half circle below) in ùhumantués, double tilde, first and second halves in únûgalan, high comma (centered) in gþeotermika.", "Diacritics test ok");

#=500  \\$aThis is a test of diacritics like the uppercase Polish L in {Lstrok}{acute}od{acute}z, the uppercase Scandinavia O in {Ostrok}st, the uppercase D with crossbar in {Dstrok}uro, the uppercase Icelandic thorn in {THORN}ann, the uppercase digraph AE in {AElig}gir, the uppercase digraph OE in {OElig}uvres, the soft sign in rech{softsign}, the middle dot in col{middot}lecci{acute}o, the musical flat in F{flat}, the patent mark in Frizbee{reg}, the plus or minus sign in {plusmn}54%, the uppercase O-hook in B{Ohorn}, the uppercase U-hook in X{Uhorn}A, the alif in mas{mlrhring}alah, the ayn in {mllhring}arab, the lowercase Polish l in W{lstrok}oc{lstrok}aw, the lowercase Scandinavian o in K{ostrok}benhavn, the lowercase d with crossbar in {dstrok}avola, the lowercase Icelandic thorn in {thorn}ann, the lowercase digraph ae in v{aelig}re, the lowercase digraph oe in c{oelig}ur, the lowercase hardsign in s{hardsign}ezd, the Turkish dotless i in masal{inodot}, the British pound sign in {pound}5.95, the lowercase eth in ver{eth}ur, the lowercase o-hook (with pseudo question mark) in S{hooka}{ohorn}, the lowercase u-hook in T{uhorn} D{uhorn}c, the pseudo question mark in c{hooka}ui, the grave accent in tr{grave}es, the acute accent in d{acute}esir{acute}ee, the circumflex in c{circ}ote, the tilde in ma{tilde}nana, the macron in T{macr}okyo, the breve in russki{breve}i, the dot above in {dot}zaba, the dieresis (umlaut) in L{uml}owenbr{uml}au, the caron (hachek) in {caron}crny, the circle above (angstrom) in {ring}arbok, the ligature first and second halves in d{llig}i{rlig}ad{llig}i{rlig}a, the high comma off center in rozdel{rcommaa}ovac, the double acute in id{dblac}oszaki, the candrabindu (breve with dot above) in Ali{candra}iev, the cedilla in {cedil}ca va comme {cedil}ca, the right hook in viet{ogon}a, the dot below in te{dotb}da, the double dot below in {under}k{under}hu{dbldotb}tbah, the circle below in Sa{dotb}msk{ringb}rta, the double underscore in {dblunder}Ghulam, the left hook in Lech Wa{lstrok}{commab}esa, the right cedilla (comma below) in kh{rcedil}ong, the upadhmaniya (half circle below) in {breveb}humantu{caron}s, double tilde, first and second halves in {ldbltil}n{rdbltil}galan, high comma (centered) in g{commaa}eotermika.

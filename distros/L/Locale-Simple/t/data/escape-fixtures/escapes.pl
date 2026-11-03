# Perl: double quotes know the C escapes, hex, octal, named and control
# characters; single quotes only \\ and \'.
l("PL newline\n");
l("PL tab\tand return\r");
l("PL backslash \\ quote \" dollar \$ at \@ unknown \q");
l("PL hex \x41\x{e4}\x{263A} octal \101\o{101} named \N{U+00DF}\N{LATIN SMALL LETTER O WITH DIAERESIS} control \cI");
l('PL single \n stays, \\ is one, \' is a quote');
l("PL joined\n" . 'PL raw\t' . "\tPL end");
ln("PL one\n", "PL many\n", $n);
l("0");
lp("0", "PL context zero");
l("PL \Ucase\E is not read");

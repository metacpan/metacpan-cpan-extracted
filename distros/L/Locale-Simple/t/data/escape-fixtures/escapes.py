# Python: the same escapes in both quotes; an unknown one keeps its backslash.
l("PY newline\n")
l('PY single \'quote\' and tab\t')
l("PY backslash \\ quote \" keeps \q")
l("PY hex \x41 unicode ä \U0001F600 named \N{LATIN SMALL LETTER SHARP S} octal \101")
l("PY continued \
line")
l("PY joined\n" + 'PY end\t')
ln("PY one\n", "PY many\n", n)
l("0")
lp("0", "PY context zero")
l("PY bad \x4 is not read")

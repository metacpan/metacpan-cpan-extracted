// JavaScript: the same escapes in both quotes.
l("JS newline\n");
l('JS single \'quote\' and tab\t');
l("JS backslash \\ quote \" unknown \q \8");
l("JS hex \x41 unicode ä \u{263A} \u{1F600} pair 😀 octal \101");
l("JS continued \
line");
l("JS joined\n" + 'JS end\t');
ln("JS one\n", "JS many\n", n);
l("0");
lp("0", "JS context zero");
l("JS bad \x4 is not read");

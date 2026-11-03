# Perl: a double-quoted literal that interpolates is not a msgid; the calls in
# its arguments still are. Escaped sigils and an @ without a name are text.
l("PL hello $name is not read %s", l("PL inner of interpolation"));
l("PL list @items is not read");
l("PL block ${name} is not read");
l("PL expression @{[ 1 + 1 ]} is not read");
l("PL mail user@example.com is not read");
l("PL joined " . "PL $name is not read");
ln("PL one $name is not read", "PL many", $n);
ln("PL one", "PL many @items is not read", $n);
lp("PL ctx $name", "PL context is not read");
l("PL escaped \$name and \@items and \${name} and %2\$s");
l("PL at @ sign, 100% and 5 \$");
l('PL single $name @items ${name}');
# Every $ in double quotes names a variable: digits, punctuation, packages,
# carets, a name after whitespace. A final $ does not compile.
l("PL total $%.2f is not read", $x);
l("PL position %1$s is not read", $x);
l("PL match $1 and $10 is not read");
l("PL package $::name and $'name is not read");
l("PL pid $$ and topic $_ is not read");
l("PL punctuation $& $. $, $; $! $@ $0 is not read");
l("PL bracket $( $) $[ $] $< $> $| $? is not read");
l("PL caret $^W and $^ alone is not read");
l("PL cost $ total is not read");
l("PL record separator $\n is not read");
l("PL final dollar is not read $");
# @ followed by a name, ::, ', $, +, -, a digit or { names an array.
l("PL array @::list and @_ is not read");
l("PL digit array @0 is not read");
l("PL deref @$ref is not read");
l("PL match arrays @- and @+ is not read");
l("PL old package @'list is not read");
l("PL colon array @: is not read");
{ use utf8; l("PL utf8 name @änne is not read"); }
# Under use utf8 perl up to 5.40 keeps a digit after @ as text; 5.44 reads
# the array.
{ use utf8; l("PL utf8 digit array @0 is not read"); }
# Any other @ is text.
l("PL lone @ and @. and @! and @, and @% and @@ stay");
{ use utf8; l("PL euro @€ and arabic digit @٣ stay"); }

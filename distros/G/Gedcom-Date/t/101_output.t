use strict;
use warnings;

use Gedcom::Date;

use Test::More;

# -------------------

chomp(my $langs = <DATA>);

my(@lang) = split(/\s*:\s*/, $langs);

my(@data);

while (my $gedcom = <DATA>)
{
	chomp($gedcom);

	my($d) =
	{
		date   => Gedcom::Date -> parse($gedcom),
		gedcom => $gedcom,
	};

    for my $lang (@lang)
	{
		chomp(my $str = <DATA>);

		$str		=~ s/^\s*//;
		$$d{$lang}	= $str;
    }

    push @data, $d;
}

for my $data (@data)
{
	for my $lang (@lang)
	{
		is($$data{date}->as_text($lang), "$$data{$lang}", "Language: $lang. Date: $$data{$lang}");
    }
}

done_testing();

__DATA__
: en : nl
10 JUL 2003
    on 10 July 2003
    on July 10, 2003
    op 10 juli 2003
JUL 2003
    in July 2003
    in July 2003
    in juli 2003
2003
    in 2003
    in 2003
    in 2003
ABT 10 JUL 2003
    about 10 July 2003
    about July 10, 2003
    rond 10 juli 2003
CAL 10 JUL 2003
    about 10 July 2003
    about July 10, 2003
    rond 10 juli 2003
EST 10 JUL 2003
    about 10 July 2003
    about July 10, 2003
    rond 10 juli 2003
FROM 10 JUL 2003
    from 10 July 2003
    from July 10, 2003
    vanaf 10 juli 2003
TO 10 JUL 2003
    to 10 July 2003
    to July 10, 2003
    tot 10 juli 2003
FROM 10 JUL 2003 TO 20 JUL 2003
    from 10 July 2003 to 20 July 2003
    from July 10, 2003 to July 20, 2003
    van 10 juli 2003 tot 20 juli 2003
AFT 10 JUL 2003
    after 10 July 2003
    after July 10, 2003
    na 10 juli 2003
BEF 10 JUL 2003
    before 10 July 2003
    before July 10, 2003
    voor 10 juli 2003
BET 10 JUL 2003 AND 20 JUL 2003
    between 10 July 2003 and 20 July 2003
    between July 10, 2003 and July 20, 2003
    tussen 10 juli 2003 en 20 juli 2003
INT 10 JUL 2003 (foo)
    on 10 July 2003
    on July 10, 2003
    op 10 juli 2003
(foo)
    (foo)
    (foo)
    (foo)

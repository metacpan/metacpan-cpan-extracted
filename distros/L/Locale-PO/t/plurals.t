# $Id: plurals.t,v 1.1 2005/10/17 22:14:52 evdb Exp $
# Copyright 2005. Distributed under the same licence as Perl itself.
# Author: Edmund von der Burg <evdb@ecclestoad.co.uk>

use strict;
use warnings;

use Test::More 'no_plan';
use File::Slurp;

use_ok 'Locale::PO';

my $pos = Locale::PO->load_file_asarray("t/plurals.pot");
ok $pos, "loaded plurals.pot file";

my $out = $pos->[0]->dump;
ok $out, "dumped po object";

ok Locale::PO->save_file_fromarray( "t/plurals.pot.out", $pos ), "save to file";
ok -e "t/plurals.pot.out", "the file now exists";

SKIP: {
	if ($^O eq 'msys') {
		skip(1, "Comparing POs after a roundtrip fails on msys platform");
	}
	is(
		read_file('t/plurals.pot'),
		read_file('t/plurals.pot.out'),
		"found no matches - good"
	  )
	  && unlink 't/plurals.pot.out';
}

{    # Check that the plurals can be created in code.

    my $po = Locale::PO->new(
        -msgid        => '%d test',
        -msgid_plural => '%d tests',
        -msgstr_n     => { 0 => '%d TEST', 1 => '%d TESTS' },
    );
    ok $po, "object created.";

    my $expected = join "\n", 'msgid "%d test"', 'msgid_plural "%d tests"',
      'msgstr[0] "%d TEST"', 'msgstr[1] "%d TESTS"', '', '';

    is $po->dump, $expected, "check the output";

    # try to edit the plurals in the code.

    ok $po->msgstr_n( { 1 => '%d TeStS' } ),
      "change the value of a plurals translation";

    $expected =~ s/TESTS/TeStS/;
    is $po->dump, $expected, "check the output";

}

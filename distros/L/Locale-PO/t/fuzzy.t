# $Id: fuzzy.t,v 1.1 2011/02/28 14:33:10 evdb Exp $
# Copyright 2005. Distributed under the same licence as Perl itself.
# Author: Joshua Miller <unrtst@cpan.org>

use strict;
use warnings;

use Test::More 'no_plan';
use File::Slurp;

use_ok 'Locale::PO';

my $pos = Locale::PO->load_file_asarray("t/fuzzy.pot");
ok $pos, "loaded fuzzy.pot file";

my $out = $pos->[0]->dump;
ok $out, "dumped po object";

ok Locale::PO->save_file_fromarray( "t/fuzzy.pot.out", $pos ), "save to file";
ok -e "t/fuzzy.pot.out", "the file now exists";

SKIP: {
	if ($^O eq 'msys') {
		skip(1, "Comparing POs after a roundtrip fails on msys platform");
	}
	is(
		read_file('t/fuzzy.pot'),
		read_file('t/fuzzy.pot.out'),
		"found no matches - good"
	  )
	  && unlink 't/fuzzy.pot.out';
}

{    # Check that the fuzzy can be created in code.

    my $po = Locale::PO->new(
        -fuzzy_msgid        => 'one test',
        -fuzzy_msgid_plural => '%d tests',
        -msgid              => '%d test',
        -msgid_plural       => '%d tests',
        -msgstr_n           => { 0 => '%d TEST', 1 => '%d TESTS' },
    );
    ok $po, "object created.";

    my $expected = join "\n", '#| msgid "one test"', '#| msgid_plural "%d tests"',
      'msgid "%d test"', 'msgid_plural "%d tests"',
      'msgstr[0] "%d TEST"', 'msgstr[1] "%d TESTS"', '', '';

    is $po->dump, $expected, "check the output";

    # try to edit the fuzzy in the code.

    ok $po->fuzzy_msgid( 'one TeSt' ),
      "change the value of a fuzzy msgid";

    $expected =~ s/one test/one TeSt/;
    is $po->dump, $expected, "check the output";

}

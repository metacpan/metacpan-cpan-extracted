use Test::Simple tests => 9;

use Language::Nouse;

my $nouse = new Language::Nouse;
ok($nouse);

#
# simple load/saves
#

$nouse->clear();
$nouse->load_linenoise('<0>6^0?2+1');
ok($nouse->get_linenoise() eq '<0>6^0?2+1');
ok($nouse->get_assembly eq "read 0, write 6, swap 0, test 2\nadd 1\n");

$nouse->clear();
$nouse->load_assembly('read 0, write 6, swap 0, test 2, add 1');
ok($nouse->get_linenoise() eq '<0>6^0?2+1');
ok($nouse->get_assembly eq "read 0, write 6, swap 0, test 2\nadd 1\n");

#
# compound load/saves
#

$nouse->clear();
$nouse->load_linenoise('<0>6^0');
$nouse->load_linenoise('?2+1');
ok($nouse->get_linenoise() eq '<0>6^0?2+1');
ok($nouse->get_assembly eq "read 0, write 6, swap 0, test 2\nadd 1\n");

$nouse->clear();
$nouse->load_assembly('read 0, write 6, swap 0');
$nouse->load_assembly('test 2, add 1');
ok($nouse->get_linenoise() eq '<0>6^0?2+1');
ok($nouse->get_assembly eq "read 0, write 6, swap 0, test 2\nadd 1\n");

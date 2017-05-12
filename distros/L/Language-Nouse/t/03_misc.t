use Test::Simple tests => 3;

use Language::Nouse;

my $nouse = new Language::Nouse;
ok($nouse);

#
# comments
#

$nouse->load_assembly('read 0, write 6, swap 0, test 2, add 1, # add 12');
ok($nouse->get_linenoise() eq '<0>6^0?2+1');
ok($nouse->get_assembly eq "read 0, write 6, swap 0, test 2\nadd 1\n");


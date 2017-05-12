use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Hobocamp::Dialog') }

my $fail = 0;
foreach my $constname (
    qw(
    DLG_EXIT_CANCEL
    DLG_EXIT_ERROR DLG_EXIT_ESC DLG_EXIT_EXTRA DLG_EXIT_HELP
    DLG_EXIT_ITEM_HELP DLG_EXIT_OK DLG_EXIT_UNKNOWN)
  ) {
    next if (eval "my \$a = &Hobocamp::Dialog::$constname; 1");
    if ($@ =~ /^Your vendor has not defined Hobocamp macro $constname/) {
        print "# pass: $@";
    }
    else {
        print "# fail: $@";
        $fail = 1;
    }
}

ok($fail == 0, 'Constants');

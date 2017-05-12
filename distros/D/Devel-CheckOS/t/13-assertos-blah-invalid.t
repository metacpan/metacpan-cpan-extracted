use strict;
$^W = 1;

use File::Spec;
use lib File::Spec->catdir(qw(t lib));

use Test::More;
END { done_testing }

eval "use Devel::AssertOS";
ok($@ =~ /needs at least one param/i,
    "'use Devel::AssertOS' needs at least one param");

eval "use Devel::AssertOS::NotAnOperatingSystem";
ok($@ =~ /OS unsupported/i);

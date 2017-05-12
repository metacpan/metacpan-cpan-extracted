use Test::More tests => 3;

use errors -with_using;

ok not(defined &with), "-with_using doesn't export with";
ok defined(&using), "-with_using exports using";

try {
    throw Exception "Bad";
}
catch Exception using {
    pass "catch with using";
    return;
}


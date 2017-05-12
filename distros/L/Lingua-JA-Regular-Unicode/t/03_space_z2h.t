use strict;
use warnings;
use utf8;
use Test::More;
use Data::Section::TestBase;

use Lingua::JA::Regular::Unicode;

for my $block (blocks) {
    is space_z2h(eval $block->input), eval $block->expected;
}
done_testing;

__END__

===
--- input:    "\x{3000}eee"
--- expected: "\x{0020}eee"


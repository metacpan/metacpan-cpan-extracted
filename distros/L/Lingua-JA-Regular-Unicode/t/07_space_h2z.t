use utf8;
use strict;
use warnings;
use Data::Section::TestBase;
use Test::More;
use utf8;
use Lingua::JA::Regular::Unicode;

for my $block (blocks) {
    is space_h2z(eval $block->input), eval $block->expected;
}
done_testing;

__END__

===
--- input:    "\x{0020}eee"
--- expected: "\x{3000}eee"


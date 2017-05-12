
# Author's note: My very first module test :)

use Test;
BEGIN { plan tests => 20 };
use Math::MagicSquare::Generator;
for (1..20) {
    ok(Math::MagicSquare::Generator->new(size => 1 + 2 * int rand 100)->check);
}
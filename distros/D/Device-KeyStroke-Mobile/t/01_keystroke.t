use Test::More;
use Device::KeyStroke::Mobile;

my @Tests = (
    [ 'example.com', 21 ],
    [ 'foo.jp', 13 ],
);

plan tests => scalar(@Tests);

for my $test (@Tests) {
    is calc_keystroke($test->[0]), $test->[1], "$test->[0]: $test->[1]";
}


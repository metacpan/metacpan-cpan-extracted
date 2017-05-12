use strict;
use warnings;
use Test::Base;

use Encode;
use Encode::DoubleEncodedUTF8;

filters {
    input => [ 'chomp', 'string' ],
    expected => [ 'chomp', 'string' ]
};

sub string {
    my $str = shift;
    eval qq("$str");
}

plan tests => 1 * blocks;

run {
    my $block = shift;
    is decode("utf-8-de", $block->input), $block->expected;
}

__END__

=== Unicode + UTF-8
--- input
\xe5\xae\xae\xc3\xa5\xc2\xae\xc2\xae
--- expected
\x{5bae}\x{5bae}

=== Unicode + UTF-8 (double)
--- input
\xe5\xae\xae\xc3\xa5\xc2\xae\xc2\xae\xe5\xae\xae\xc3\xa5\xc2\xae\xc2\xae
--- expected
\x{5bae}\x{5bae}\x{5bae}\x{5bae}

=== More than 2 characters
--- input
\xc3\xa5\xc2\xae\xc2\xae\xc3\xa5\xc2\xae\xc2\xae
--- expected
\x{5bae}\x{5bae}

=== Dodgy Latin-1
--- input
Hello LÃ©on
--- expected
Hello L\x{e9}on

=== Safe latin-1
--- input
Hello Léon
--- expected
Hello L\x{e9}on

=== Safe latin-1 + dodgy utf-8
--- input
Léon \xe5\xae\xae\xc3\xa5\xc2\xae\xc2\xae
--- expected
L\x{e9}on \x{5bae}\x{5bae}

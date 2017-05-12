use Test::Base;
use FormValidator::LazyWay::Rule::String;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::String::ascii( $block->value );
    is( $result, $block->result );
}

__END__

=== alphabets
--- value  chomp
abcdefg
--- result chomp
1
=== numbers
--- value  chomp
12345467
--- result chomp
1
=== simbols
--- value  chomp
!"#$%&'()-=~|,./_<>?;:]+*}@[`{
--- result chomp
1
=== multibyte
--- value  chomp
ほげらほげら
--- result chomp
0

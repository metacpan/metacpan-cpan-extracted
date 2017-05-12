use Test::Base;
use FormValidator::LazyWay::Rule::String;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::String::number( $block->value );
    is( $result, $block->result );
}

__END__

=== ok
--- value chomp
1234990
--- result chomp
1
=== ng
--- value chomp
abcde
--- result chomp
0
=== ng
--- value chomp
１２３４５６７
--- result chomp
0
=== not ok
--- value  chomp
あいうえお
--- result chomp
0
=== not ok
--- value  chomp
abc def
--- result chomp
0
=== not ok
--- value  chomp
123 44567
--- result chomp
0

use Test::Base;
use FormValidator::LazyWay::Rule::String;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::String::alphabet( $block->value );
    is( $result, $block->result );
}

__END__

=== ok
--- value chomp
abcdefg
--- result chomp
1
=== ok
--- value chomp
AbcDef
--- result chomp
1
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
12344567
--- result chomp
0

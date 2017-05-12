use Test::Base;
use FormValidator::LazyWay::Rule::Object;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::Object::true( $block->value );
    is( $result, $block->result );
}

__END__

=== 1
--- value chomp
1
--- result chomp
1
=== 2
--- value chomp
--- result chomp
1
=== 3
--- value chomp
あいうえ
--- result chomp
1
=== 3
--- value chomp
hogehoge
--- result chomp
1

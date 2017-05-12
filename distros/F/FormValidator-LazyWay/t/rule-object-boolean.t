use Test::Base;
use FormValidator::LazyWay::Rule::Object;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::Object::boolean( $block->value );
    is( $result, $block->result );
}

__END__

=== 1
--- value chomp
1
--- result chomp
1
=== 2
--- value eval
--- result chomp
0
=== 3
--- value eval
adf
--- result chomp
0
=== 3
--- value eval
0
--- result chomp
1

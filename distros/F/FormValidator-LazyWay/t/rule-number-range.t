use Test::Base;
use FormValidator::LazyWay::Rule::Number;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::Number::range( $block->value , $block->args );
    is( $result, $block->result );
}

__END__

=== ok
--- value  chomp
3
--- args eval
{
    min => 2,
    max => 4
}
--- result chomp
1
=== ok min
--- value  chomp
2
--- args eval
{
    min => 2,
    max => 4
}
--- result chomp
1
=== ok max
--- value  chomp
4
--- args eval
{
    min => 2,
    max => 4
}
--- result chomp
1
=== ng min
--- value  chomp
1
--- args eval
{
    min => 2,
    max => 4
}
--- result chomp
0
=== ng max
--- value  chomp
5
--- args eval
{
    min => 2,
    max => 4
}
--- result chomp
0

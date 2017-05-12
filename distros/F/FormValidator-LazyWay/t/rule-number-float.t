use Test::Base;
use FormValidator::LazyWay::Rule::Number;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::Number::float( $block->value );
    is( $result, $block->result );
}

__END__

=== ok
--- value  chomp
1
--- result chomp
1
=== negative
--- value  chomp
-1
--- result chomp
1
=== negative
--- value  chomp
-123243
--- result chomp
1
=== 0
--- value  chomp
0
--- result chomp
1
=== number
--- value  chomp
12131
--- result chomp
1
=== err
--- value  chomp
012131
--- result chomp
0
=== err
--- value  chomp
-012131
--- result chomp
0
=== err
--- value  chomp
hoge
--- result chomp
0
=== flooat
--- value  chomp
234242424242.234
--- result chomp
1
=== flooat
--- value  chomp
-234242424242.234
--- result chomp
1
=== flooat
--- value  chomp
00.234
--- result chomp
0
=== flooat
--- value  chomp
-0.234
--- result chomp
1
=== flooat
--- value  chomp
+0.234
--- result chomp
1

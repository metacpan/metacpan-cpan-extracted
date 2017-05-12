use Test::Base;
use FormValidator::LazyWay::Rule::DateTime;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::DateTime::time( $block->value, $block->args );
    is( $result, $block->result );
}

__END__

=== ok
--- value  chomp
00:43:58
--- result chomp
1
=== format ok
--- value  chomp
00-43-58
--- args eval
{ pattern => '%H-%M-%S' }
--- result chomp
1
=== hour not ok
--- value  chomp
25:43:58
--- result chomp
0
=== minute not ok
--- value  chomp
23:64:58
--- result chomp
0
=== seconds not ok
--- value  chomp
23:34:81
--- result chomp
0

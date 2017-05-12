use Test::Base;
use FormValidator::LazyWay::Rule::DateTime;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::DateTime::date( $block->value, $block->args );
    is( $result, $block->result );
}

__END__

=== ok
--- value  chomp
2009-08-28
--- result chomp
1
=== day not ok
--- value  chomp
2009-08-32
--- result chomp
0
=== format ok
--- value  chomp
2009/08/28
--- args eval
{ pattern => '%Y/%m/%d' }
--- result chomp
1
=== format not ok
--- value  chomp
2009/15/28
--- args eval
{ pattern => '%Y/%m/%d' }
--- result chomp
0
=== month not ok
--- value  chomp
2009-13-12
--- result chomp
0
=== leap year ok
--- value  chomp
2012-02-29
--- result chomp
1
=== leap year not ok
--- value  chomp
2011-02-29
--- result chomp
0

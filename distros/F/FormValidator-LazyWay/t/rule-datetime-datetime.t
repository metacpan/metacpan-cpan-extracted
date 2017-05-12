use Test::Base;
use FormValidator::LazyWay::Rule::DateTime;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::DateTime::datetime( $block->value, $block->args );
    is( $result, $block->result );
}

__END__

=== ok
--- value  chomp
2009-08-28 00:43:58
--- result chomp
1
=== format ok
--- value  chomp
2009/08/28 00:43:58
--- args eval
{ pattern => '%Y/%m/%d %H:%M:%S' }
--- result chomp
1
=== format not ok
--- value  chomp
2009/15/28 00:43:58
--- args eval
{ pattern => '%Y/%m/%d %H:%M:%S' }
--- result chomp
0
=== day not ok
--- value  chomp
2009-08-32 00:43:58
--- result chomp
0
=== month not ok
--- value  chomp
2009-13-12 00:43:58
--- result chomp
0
=== hour not ok
--- value  chomp
2009-11-12 25:43:58
--- result chomp
0
=== minute not ok
--- value  chomp
2009-11-12 23:64:58
--- result chomp
0
=== seconds not ok
--- value  chomp
2009-11-12 23:34:81
--- result chomp
0
=== leap year ok
--- value  chomp
2012-02-29 12:24:52
--- result chomp
1
=== leap year not ok
--- value  chomp
2011-02-29 12:24:52
--- result chomp
0

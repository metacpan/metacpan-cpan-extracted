use Test::Base;
use FormValidator::LazyWay::Rule::Net;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::Net::uri( $block->value );
    is( $result, $block->result );
}

__END__

=== ok
--- value chomp
http://hogehoge.com/hogehoge/
--- result chomp
1
=== ok
--- value chomp
https://hogehoge.com/hogehoge/
--- result chomp
1
=== ok
--- value chomp
ftp://hogehoge.com/hogehoge/
--- result chomp
1
=== ng
--- value chomp
hogehoge.com/hogehoge/
--- result chomp
0

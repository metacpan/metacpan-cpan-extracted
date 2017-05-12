use Test::Base;
use FormValidator::LazyWay::Rule::Object;
use utf8;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::Object::regexp( $block->value , { format => $block->format } );
    is( $result, $block->result );
}

__END__

=== 1
--- value chomp
hogehoge
--- format chomp
\w+
--- result chomp
1
=== 2
--- value chomp
333-333
--- format chomp
^\d{3}-\d{3}$
--- result chomp
1

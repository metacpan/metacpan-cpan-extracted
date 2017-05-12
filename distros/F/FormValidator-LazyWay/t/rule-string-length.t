use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use FormValidator::LazyWay::Rule::String;
use MyTestBase;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::String::length( $block->value, $block->args );
    is( $result, $block->result );
}

__END__

=== ok
--- value  chomp
abcdefg
--- args yaml
min: 5
max: 10
--- result chomp
1
=== ok
--- value  chomp
あいうえお
--- args yaml
min: 3
max: 8
--- result chomp
1
=== not ok
--- value  chomp
abc
--- args yaml
min: 4
max: 6
--- result chomp
0
=== not ok
--- value  chomp
abcdefg
--- args yaml
min: 4
max: 6
--- result chomp
0
=== multibyte is not ok
--- value  chomp
ほげら
--- args yaml
min: 4
max: 6
--- result chomp
0
=== multibyte is not ok
--- value  chomp
ほげらほげらあ
--- args yaml
min: 4
max: 6
--- result chomp
0

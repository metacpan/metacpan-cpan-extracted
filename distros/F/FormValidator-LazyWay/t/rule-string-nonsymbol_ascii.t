use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use FormValidator::LazyWay::Rule::String;
use MyTestBase;

plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $result = FormValidator::LazyWay::Rule::String::nonsymbol_ascii( $block->value, $block->args );
    is( $result, $block->result );
}

__END__

=== alphabets
--- value  chomp
abcdefg
--- result chomp
1
=== numbers
--- value  chomp
12345467
--- result chomp
1
=== numbers and alphabets
--- value  chomp
vkgtaro1977
--- result chomp
1
=== anderscore
--- value  chomp
vkgtaro_1977
--- args yaml
allow:
  - '_'
--- result chomp
1
=== hyphen
--- value  chomp
vkgtaro-1977
--- args yaml
allow:
  - '-'
--- result chomp
1
=== simbols
--- value  chomp
!"#$%&'()-=~|,./_<>?;:]+*}@[`{
--- result chomp
0
=== multibyte
--- value  chomp
ほげらほげら
--- result chomp
0

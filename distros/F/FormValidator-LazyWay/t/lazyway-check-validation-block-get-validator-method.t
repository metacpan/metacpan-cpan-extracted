use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use FormValidator::LazyWay;
use MyTestBase;

plan tests => 3 * blocks;

run {
    my $block = shift;
    my $fv = FormValidator::LazyWay->new( { config => $block->config } );
    my $level = $block->level;
    my $regex = '';
    my $validators = $fv->_get_validator_methods( 'email' , \$level  , \$regex );

    foreach my $validator ( @{$validators} ) {
        ok( $validator->{method}->( $block->ok ) ) ;
        ok( !$validator->{method}->($block->ng ) );
        is( $validator->{label} , $block->label );
    }
}

__END__
=== normal
--- config yaml
rules :
    - Email
    - +MyRule::Oppai
setting :
    strict :
        email :
            rule :
                - Email#email
lang  : ja
messages :
    ja :
        rule :
            Email#email : メールアドレス
            +MyRule::Oppai#name : ぼいん
--- level chomp
strict
--- ok chomp
foo@foo.com
--- ng chomp
hoge
--- label chomp
Email#email
=== alias
--- config yaml
rules :
    - e=Email
    - +MyRule::Oppai
setting :
    strict :
        email :
            rule :
                - e#email
lang  : ja
messages :
    ja :
        rule :
            e#email : メールアドレス
            +MyRule::Oppai#name : ぼいん
--- level chomp
strict
--- ok chomp
foo@foo.com
--- ng chomp
hoge
--- label chomp
Email#email

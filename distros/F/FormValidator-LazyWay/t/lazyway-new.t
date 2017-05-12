use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use FormValidator::LazyWay;
use MyTestBase;

plan tests => 2 * blocks;

run {
    my $block = shift;
    my $fv = FormValidator::LazyWay->new( { config => $block->config } );
    is( ref $fv->rule , 'FormValidator::LazyWay::Rule' );   
    is( ref $fv->message , 'FormValidator::LazyWay::Message' );
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
                - Email::email
        oppai : 
            rule :
                - +MyRule::Oppai::name
lang  : ja
messages :
    ja :
        rule :
            Email::email : メールアドレス
            +MyRule::Oppai::name : ぼいん

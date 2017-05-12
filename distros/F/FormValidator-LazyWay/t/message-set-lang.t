use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use FormValidator::LazyWay::Message;
use FormValidator::LazyWay::Rule;
use MyTestBase;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $rule = FormValidator::LazyWay::Rule->new( config => $block->config );
    my $message = FormValidator::LazyWay::Message->new( config => $block->config , rule => $rule );
    $message->_set_lang();
    is_deeply( $message->base_message , $block->base_message ) ;

}

__END__
=== normal
--- config yaml
rules :
    - +MyRule::Oppai
    - String
setting :
    strict :
        email :
            rule :
                - String#length :
                    max : 30
                    min : 4
langs :
    - ja
    - en
lang  : ja
--- base_message eval
{
      'en' => {
                'missing' => '__field__ is missing.',
                'invalid' => '__field__ supports __rule__ .'
              },
      'ja' => {
                'missing' => '__field__が空欄です。',
                'invalid' => '__field__には、__rule__が使用できます。'
              }
}

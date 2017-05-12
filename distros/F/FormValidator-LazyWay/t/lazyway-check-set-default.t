use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use Data::Dumper;
use FormValidator::LazyWay;
use MyTestBase;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $fv = FormValidator::LazyWay->new( { config => $block->config } );
    my $storage = $block->storage;
    $fv->_set_default(  $storage );
    is_deeply( $storage , $block->result );
}

__END__
=== set default
--- storage eval
{
    valid => { 
        hoge => 'hoge',
    },
}
--- config yaml
defaults :
    email : tomohiro.teranishi@gmail.com
lang : ja
rules :
    - Email
    - +MyRule::Oppai
setting :
    strict :
        email :
            rule :
                - Email#email
--- result eval
{
    valid => {
        hoge => 'hoge',
        email => 'tomohiro.teranishi@gmail.com',
    }
}
=== no default
--- storage eval
{
    valid => { 
        hoge => 'hoge',
        email => 'hoge@hoge.com',
    },
}
--- config yaml
defaults :
    email : tomohiro.teranishi@gmail.com
lang : ja
rules :
    - Email
    - +MyRule::Oppai
setting :
    strict :
        email :
            rule :
                - Email#email
--- result eval
{
    valid => {
        hoge => 'hoge',
        email => 'hoge@hoge.com',
    }
}

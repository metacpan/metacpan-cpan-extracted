use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

use FormValidator::LazyWay;
use MyTestBase;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $fv = FormValidator::LazyWay->new( { config => $block->config } );
    my $storage = $block->storage;
    $fv->_remove_empty_fields(  $storage );
    is_deeply( $storage , $block->result );
}
__END__
=== set default
--- storage eval
{
    valid => { 
        hoge => 'hoge',
        oppai => '',
    },
}
--- config yaml
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
    }
}

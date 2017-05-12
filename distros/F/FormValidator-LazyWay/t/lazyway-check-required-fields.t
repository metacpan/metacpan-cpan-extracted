use Test::Base;
use FormValidator::LazyWay;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $storage = $block->storage;
    my $profile = $block->profile;
    FormValidator::LazyWay->_conv_profile( $storage , $profile );
    FormValidator::LazyWay->_check_required_fields( $storage , $profile );
    is_deeply( $storage , $block->result );
}

__END__
=== normal
--- profile eval
{
    required => [qw/foo bar/],
}
--- storage eval
{
    valid    => {
        foo =>'hoge',
        moo =>'hoge',
    },
    missing => [],
}
--- result eval
{
    valid => { 
        foo =>'hoge',
        moo => 'hoge',
    },
    missing => [
        'bar',
    ],
} 

use Test::Base;
use FormValidator::LazyWay;
use FormValidator::LazyWay::Utils;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

plan tests => 1 * blocks;

run {
    my $block   = shift;
    my $storage = $block->storage;
    my $profile = $block->profile;
    FormValidator::LazyWay->_conv_profile( $storage, $profile );
    FormValidator::LazyWay->_set_unknown( $storage, $profile );
    is_deeply( $storage, $block->result );
}

__END__

=== normal
--- storage eval
{
    valid  => {
        foo => 1,
        hoge => 1,
        oppai => 1,
    },
    unknown => [ ],
}
--- profile eval
{
    required => [qw/foo/],
    optional => [qw/hoge/],
}
--- result eval
{
    valid => {
        foo => 1,
        hoge => 1,
    },
    unknown => [
        'oppai',
    ],
}
=== array
--- storage eval
{
    valid  => {
        foo => [1,2,3],
        hoge => 1,
        oppai => [1,2,3],
    },
    unknown => [ ],
}
--- profile eval
{
    required => [qw/foo/],
    optional => [qw/hoge/],
}
--- result eval
{
    valid => {
        foo => [1,2,3],
        hoge => 1,
    },
    unknown => [
        'oppai',
    ],
}

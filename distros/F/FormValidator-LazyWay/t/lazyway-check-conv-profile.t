use Test::Base;
use FormValidator::LazyWay;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use utf8;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $profile = $block->profile;
    FormValidator::LazyWay->_conv_profile( undef , $profile );
    is_deeply( $profile , $block->result );
}

__END__
=== normal no stash
--- profile eval
{
    required => [qw/foo bar/],
    optional => [qw/foo bar hoge/],
    want_array => [qw/oppai/],
}
--- result eval
{
    required => {
        foo => 1,
        bar => 1,
    },
    optional => {
        foo => 1,
        bar => 1,
        hoge => 1,
    },
    want_array => {
        oppai => 1,
    },
    stash => undef,
} 

=== normal
--- profile eval
{
    required => [qw/foo bar/],
    optional => [qw/foo bar hoge/],
    want_array => [qw/oppai/],
    stash    => { foo => 'fuga' },
}
--- result eval
{
    required => {
        foo => 1,
        bar => 1,
    },
    optional => {
        foo => 1,
        bar => 1,
        hoge => 1,
    },
    want_array => {
        oppai => 1,
    },
    stash => {
        foo => 'fuga',
    },
} 

#!perl -w
use strict;
use Test::More;

use Dist::Maker::Config;

my $config = Dist::Maker::Config->new(user_data => {
    user => {
        name  => 'foo',
        email => 'bar',
    },
    namespace   => 'Fuga',
    user_custom => 'piyo',
});

# default
is $config->data->{core}{verbose}, 0;
is $config->data->{template}{default}, 'Default';
is $config->data->{user_custom}, 'piyo';
is_deeply $config->data->{template}{module}, ['Time::Piece'];

my $data = $config->merge_data(
    $config->data,
    { foo => 42 },
    { template => { module => ['Scalar::Util'] } },
    { namespace => 'Hoge' },
);


# custom
is $data->{user}{name},  'foo';
is $data->{user}{email}, 'bar';
is $data->{foo}, 42;
is $data->{user_custom}, 'piyo';
is_deeply $data->{namespace}, [qw/Fuga Hoge/];
is join(' ', @{$data->{template}{module}}), join(' ', 'Time::Piece', 'Scalar::Util');

done_testing;

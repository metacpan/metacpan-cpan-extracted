use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
use Mock::Sub;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

# deprecated string key param
{
    my $k;

    my $ok = eval {
        $k = tie my $sv, 'IPC::Shareable', 'TEST', {create => 1, destroy => 1};
        1;
    };

    is $ok, 1, "IPC::Shareable accepts old string way of sending in key";
    is $k->attributes('key'), 'TEST', "...and the key is ok";
    is $k->seg->key, 4008350648 - 0x80000000, "...and the converted seg key is ok";
    is $@, '', "...and no error message was set";
}

# shm key matches object key
{
    tie my $sv, 'IPC::Shareable', 'TEST', {create => 1, destroy => 1};
    is((tied $sv)->seg->key, (tied $sv)->seg->key, "Object key matches segment key ok");
}

# three letter caps
{
    my $k = tie my $sv, 'IPC::Shareable', {key => 'TES', create => 1, destroy => 1};

    is $k->{attributes}{key}, 'TES', "attr key is TES ok";
    is $k->seg->key, 3952665712 - 0x80000000, "three letter attr key is  ok";
}

# four letter caps
{
    my $k = tie my $sv, 'IPC::Shareable', {key => 'TEST', create => 1, destroy => 1};

    is $k->{attributes}{key}, 'TEST', "attr key is TEST ok";
    is $k->seg->key, 4008350648 - 0x80000000, "four letter attr key is ok";
}

# three letter lower case
{
    my $k = tie my $sv, 'IPC::Shareable', {key => 'tes', create => 1, destroy => 1};

    is $k->{attributes}{key}, 'tes', "3 letter lower case key is tes ok";
    is $k->seg->key, 2101323514, "3 letter lower case attr key is ok";
}

# six letter
{
    my $k = tie my $sv, 'IPC::Shareable', {key => 'tested', create => 1, destroy => 1};

    is $k->{attributes}{key}, 'tested', "six letter attr key is tested ok";
    is $k->seg->key, 142926612, "six letter attr key is ok";
}

# filenames
{
    my %key_hash = (
        'test/this.pl'          => 2780677640,
        'test/this.plx'         => 2191663991,
        'test/that.pl'          => 135968112,
        'test/testing/this.pl'  => 1718888502,
    );

    for (keys %key_hash) {

        my $k = tie my $sv, 'IPC::Shareable', {key => $_, create => 1, destroy => 1};

        is $k->attributes('key'), $_, "$_ as key is the proper attribute ok";

        my $key = $k->seg->key;

        if ($key_hash{$_} > 0x80000000) {
            is
                $key_hash{$_} - 0x80000000 == $k->_shm_key($_),
                1,
                "key > 0x80000000 with subtract matches _shm_key() ok";

            $key_hash{$_} = $k->_shm_key($_);
        }

        is $key, $key_hash{$_}, "...and key $_ converted to '$key' ok";

        $k->clean_up_all;
    }
}

# strings
{
    my %key_hash = (
        'thisisatest'       => 4221762593,
        'Thisisntatest'     => 447918523,
        'This is a test'    => 3229261618,
        'This isnt a test'  => 4266902788,
    );

    for (keys %key_hash) {

        my $k = tie my $sv, 'IPC::Shareable', {key => $_, create => 1, destroy => 1};

        my $attr_key = $k->attributes('key');
        is $attr_key, $_, "'$_' as key is the proper attribute ok";

        my $key = $k->seg->key;

        if ($key_hash{$_} > 0x80000000) {
            is
                $key_hash{$_} - 0x80000000 == $k->_shm_key($_),
                1,
                "key > 0x80000000 with subtract matches _shm_key() ok";

            $key_hash{$_} = $k->_shm_key($_);
        }

        is $key, $key_hash{$_}, "...and key '$_' converted to '$key' ok";

        $k->clean_up_all;
    }
}

# integers
{
    my %key_hash = (
        1       => 1,
        11      => 11,
        10      => 10,
        1000    => 1000,
        65535   => 65535,
    );

    for (keys %key_hash) {

        my $k = tie my $sv, 'IPC::Shareable', {key => $_, create => 1, destroy => 1};

        my $attr_key = $k->attributes('key');
        is $attr_key, $_, "'$_' as key is the proper attribute ok";

        my $key = $k->seg->key;
        is $key, $key_hash{$_}, "...and key '$_' converted to '$key' ok";

        $k->clean_up_all;
    }
}

# _shm_key_rand() collisions (in _mg_tie())
{

    my $m = Mock::Sub->new;
    my $sub = $m->mock('IPC::Shareable::_shm_key_rand_int');
    $sub->return_value(555555);

    my $no_collision = eval {
        tie my %h, 'IPC::Shareable', { key => 'rand key gen', create => 1, destroy => 1 };

        $h{a} = 1;
        $h{b}{c} = 2;
        $h{b}{d}{e} = 5;

        IPC::Shareable::clean_up_all;
        1;
    };

    is $no_collision, undef, "_shm_key_rand() fails if it can't find an available shm slot";
    like
        $@,
        qr/available key after 10 tries/,
        "...the error shows it attempted multiple times";
}
done_testing();

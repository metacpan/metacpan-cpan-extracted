use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
use Mock::Sub;
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before $segs_before\n" if $ENV{PRINT_SEGS};

# deprecated string key param
{
    my $k;

    my $ok = eval {
        $k = tie my $sv, 'IPC::Shareable', 'TEST', {create => 1, destroy => 1, serializer => 'storable' };
        1;
    };

    is $ok, 1, "IPC::Shareable accepts old string way of sending in key";
    is $k->attributes('key'), 'TEST', "...and the key is ok";
    is $k->seg->key, 4008350648 - 0x80000000, "...and the converted seg key is ok";
    is $@, '', "...and no error message was set";
}

# shm key matches object key
{
    tie my $sv, 'IPC::Shareable', 'TEST', {create => 1, destroy => 1, serializer => 'storable' };
    is((tied $sv)->seg->key, (tied $sv)->seg->key, "Object key matches segment key ok");
}

# three letter caps
{
    my $k = tie my $sv, 'IPC::Shareable', {key => 'TES', create => 1, destroy => 1, serializer => 'storable' };

    is $k->{attributes}{key}, 'TES', "attr key is TES ok";
    is $k->seg->key, 3952665712 - 0x80000000, "three letter attr key is  ok";
}

# four letter caps
{
    my $k = tie my $sv, 'IPC::Shareable', {key => 'TEST', create => 1, destroy => 1, serializer => 'storable' };

    is $k->{attributes}{key}, 'TEST', "attr key is TEST ok";
    is $k->seg->key, 4008350648 - 0x80000000, "four letter attr key is ok";
}

# three letter lower case
{
    my $k = tie my $sv, 'IPC::Shareable', {key => 'tes', create => 1, destroy => 1, serializer => 'storable' };

    is $k->{attributes}{key}, 'tes', "3 letter lower case key is tes ok";
    is $k->seg->key, 2101323514, "3 letter lower case attr key is ok";
}

# six letter
{
    my $k = tie my $sv, 'IPC::Shareable', {key => 'tested', create => 1, destroy => 1, serializer => 'storable' };

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

        my $k = tie my $sv, 'IPC::Shareable', {key => $_, create => 1, destroy => 1, serializer => 'storable' };

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

        my $k = tie my $sv, 'IPC::Shareable', {key => $_, create => 1, destroy => 1, serializer => 'storable' };

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

        my $k = tie my $sv, 'IPC::Shareable', {key => $_, create => 1, destroy => 1, serializer => 'storable' };

        my $attr_key = $k->attributes('key');
        is $attr_key, $_, "'$_' as key is the proper attribute ok";

        my $key = $k->seg->key;
        is $key, $key_hash{$_}, "...and key '$_' converted to '$key' ok";

        $k->clean_up_all;
    }

    # large integers are used as-is (no overflow correction)
    {
        my $k = tie my $sv, 'IPC::Shareable', {key => 3735928559, create => 1, destroy => 1, serializer => 'storable' };
        is $k->seg->key, 3735928559, "large decimal integer key used as-is (no overflow correction) ok";
        $k->clean_up_all;
    }
}

# hex keys
{
    # Stringified hex keys: the bit pattern is used directly (no overflow
    # correction), so ipcs(1) will show exactly the hex value supplied.
    my %key_hash = (
        '0x1234'     => 0x1234,
        '0xDEAD'     => 0xDEAD,
        '0xdeadbeef' => 0xdeadbeef,
        '0xDeAdBeEf' => 0xDeAdBeEf,
    );

    for my $hex_key (sort keys %key_hash) {
        my $k = tie my $sv, 'IPC::Shareable', {key => $hex_key, create => 1, destroy => 1, serializer => 'storable' };

        is $k->attributes('key'), $hex_key, "hex string key '$hex_key' stored as attribute ok";
        is $k->seg->key, $key_hash{$hex_key}, "...and '$hex_key' maps to integer $key_hash{$hex_key} (no overflow correction) ok";

        $k->clean_up_all;
    }

    # Case-insensitive: '0xDEADBEEF' and '0xdeadbeef' resolve to the same segment
    {
        tie my $a, 'IPC::Shareable', {key => '0xDEADBEEF', create => 1,  destroy => 0, serializer => 'storable' };
        tie my $b, 'IPC::Shareable', {key => '0xdeadbeef', create => 0,  destroy => 1, serializer => 'storable' };

        my $key_a = (tied $a)->seg->key;
        my $key_b = (tied $b)->seg->key;
        is $key_a, $key_b, "'0xDEADBEEF' and '0xdeadbeef' resolve to the same segment ok";

        (tied $b)->clean_up_all;
    }

    # Bare Perl hex literal (0xDEADBEEF without quotes) compiles to the decimal
    # integer 3735928559.  It takes the decimal-integer path and is also used
    # as-is, so it resolves to the same segment as the quoted '0xDEADBEEF'.
    {
        tie my $a, 'IPC::Shareable', {key => '0xDEADBEEF', create => 1,  destroy => 0, serializer => 'storable' };
        tie my $b, 'IPC::Shareable', {key =>  0xDEADBEEF,  create => 0,  destroy => 1, serializer => 'storable' };

        my $key_a = (tied $a)->seg->key;
        my $key_b = (tied $b)->seg->key;
        is $key_a, $key_b, "quoted '0xDEADBEEF' and bare 0xDEADBEEF resolve to the same segment ok";

        (tied $b)->clean_up_all;
    }
}

# _shm_key() croaks when CRC32 returns MAX_KEY_INT_SIZE (post-subtraction key == 0)
{
    my $k = tie my $sv, 'IPC::Shareable',
        { key => 'force_zero_collision', create => 1, destroy => 1, serializer => 'storable' };

    my $m = Mock::Sub->new;
    my $crc_mock = $m->mock('IPC::Shareable::crc32');
    $crc_mock->return_value(0x80000000);   # MAX_KEY_INT_SIZE

    my $ok = eval { $k->_shm_key('any string here'); 1 };
    is $ok, undef, "_shm_key() croaks when CRC32 produces a post-subtraction key of 0";
    like $@, qr/key which equals 0\. This is a fatal error/,
        "...and the error message matches the documented format";

    $crc_mock->unmock;
    IPC::Shareable->clean_up_all;
}

# _shm_key_rand() collisions (in _mg_tie())
{
    my $m = Mock::Sub->new;
    my $sub = $m->mock('IPC::Shareable::_shm_key_rand_int');
    $sub->return_value(555555);

    my $no_collision = eval {
        tie my %h, 'IPC::Shareable', { key => 'rand key gen', create => 1, destroy => 1 , serializer => 'storable' };

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

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs, even those created in separate procs, cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();

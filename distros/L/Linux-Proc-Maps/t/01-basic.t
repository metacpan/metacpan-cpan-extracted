#!perl

use warnings;
use strict;

use Path::Tiny;
use Test::More tests => 4;

BEGIN {
    use_ok('Linux::Proc::Maps');
    use_ok('Linux::Proc::Maps', qw{read_maps write_maps parse_maps_single_line format_maps_single_line});
}

subtest read_maps => sub {
    plan tests => 4;

    eval { read_maps() };
    like($@, qr/filename or pid required/i, 'Die on missing argument');

    eval { read_maps('missing-ebo3d1FHkKEAsGL3ZK89H5') };
    like($@, qr/open failed/i, 'Die on open failed');

    my $regions = read_maps(path('corpus/maps1')->absolute);
    isa_ok($regions, 'ARRAY');
    is(scalar @$regions, 20, 'Number of regions is correct');
    # note explain $regions;
};

subtest parse_maps_single_line => sub {
    plan tests => 7;

    {
        my $line    = '00400000-0040c000 r-xp 00000000 08:01 23624 /bin/cat';
        my $region  = parse_maps_single_line($line);

        isa_ok($region, 'HASH');
        is_deeply($region, {
            address_end     => 4243456,
            address_start   => 4194304,
            device          => '08:01',
            execute         => 1,
            inode           => 23624,
            offset          => 0,
            pathname        => '/bin/cat',
            read            => 1,
            shared          => '',
            write           => '',
        }, 'Region parses correctly');
        # note explain $region;
    }

    {
        my $line    = '021d8000-021f9000 rw-p 00000000 00:00 0 [heap]';
        my $region  = parse_maps_single_line($line);

        isa_ok($region, 'HASH');
        is($region->{pathname}, '[heap]', 'Heap region identified');
    }

    {
        my $line    = '7f5d1a490000-7f5d1a494000 rw-p 00000000 00:00 0 ';
        my $region  = parse_maps_single_line($line);

        isa_ok($region, 'HASH');
        is($region->{pathname}, '', 'Pathname is optional');
    }

    {
        my $line    = '7f5d1a490000-7f5d1a494000 rw-p 00000000 00:00';
        my $region  = parse_maps_single_line($line);

        is($region, undef, 'Missing inode correctly fails');
    }
};


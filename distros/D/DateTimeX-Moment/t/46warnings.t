use strict;
use warnings;

use Test::More skip_all => 'incompatible';
use Test::Warnings 0.005 ':all';

use DateTimeX::Moment;

my $year_5001_epoch = 95649120000;

SKIP:
{
    skip 'These tests require a 64-bit Perl', 2
        unless ( gmtime($year_5001_epoch) )[5] == 3101;

    {
        like(
            warning {
                DateTimeX::Moment->from_epoch(
                    epoch     => $year_5001_epoch,
                    time_zone => 'Asia/Taipei',
                );
            },
            qr{\QYou are creating a DateTimeX::Moment object with a far future year (5001) and a time zone (Asia/Taipei).},
            'got a warning when calling ->from_epoch with a far future epoch and a time_zone'
        );
    }

    {
        no warnings 'DateTimeX::Moment';
        is_deeply(
            warning {
                DateTimeX::Moment->from_epoch(
                    epoch     => $year_5001_epoch,
                    time_zone => 'Asia/Taipei',
                );
            },
            [],
            'no warning when calling ->from_epoch with a far future epoch and a time_zone with DateTimeX::Moment warnings category suppressed'
        );
    }
}

{
    like(
        warning {
            DateTimeX::Moment->new(
                year      => 5001,
                time_zone => 'Asia/Taipei',
            );
        },
        qr{\QYou are creating a DateTimeX::Moment object with a far future year (5001) and a time zone (Asia/Taipei).},
        'got a warning when calling ->new with a far future year and a time_zone'
    );
}

{
    no warnings 'DateTimeX::Moment';
    is_deeply(
        warning {
            DateTimeX::Moment->new(
                year      => 5001,
                time_zone => 'Asia/Taipei',
            );
        },
        [],
        'no warning when calling ->new with a far future epoch and a time_zone with DateTimeX::Moment warnings category suppressed'
    );
}

{
    no warnings;
    is_deeply(
        warning {
            DateTimeX::Moment->new(
                year      => 5001,
                time_zone => 'Asia/Taipei',
            );
        },
        [],
        'no warning when calling ->new with a far future epoch and a time_zone with all warnings suppressed'
    );
}

done_testing();

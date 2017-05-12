use Test::Most;
use Test::FailWarnings;
use FIX::Parser::FIX44;

my $file = 't/fix44_test.dat';
open my $info, $file or die "Could not open $file: $!";

my $fix = FIX::Parser::FIX44->new;

my @msgs;

my $line = <$info>;

@msgs = $fix->add(substr($line, 0, length($line) - 1));
is @msgs, 1, "one message parsed";

cmp_deeply(
    $msgs[0],
    superhashof({
            symbol   => 'EURJPY',
            datetime => '20151218-08:51:45.734',
            bid      => '131.362',
            ask      => '131.369',
        },
    ),
    "message contain expected data",
);

$line = <$info>;
@msgs = $fix->add(substr($line, 0, length($line) - 1));
is @msgs, 2, "2 message parsed";

cmp_deeply(
    $msgs[0],
    superhashof({
            symbol   => 'GBPNZD',
            datetime => '20151218-08:51:45.734',
            bid      => '2.22558',
            ask      => '2.22609',
        },
    ),
    "message contain expected data",
);

cmp_deeply(
    $msgs[1],
    superhashof({
            symbol   => 'NZDJPY',
            datetime => '20151218-08:51:45.735',
            bid      => '81.463',
            ask      => '81.473',
        },
    ),
    "message contain expected data",
);

done_testing;

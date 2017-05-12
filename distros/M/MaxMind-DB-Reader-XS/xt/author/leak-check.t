use strict;
use warnings;

use Test::LeakTrace;
use Test::More 0.88;

use MaxMind::DB::Reader 0.050000;

my $reader = MaxMind::DB::Reader->new(
    file => 'maxmind-db/test-data/MaxMind-DB-test-ipv4-24.mmdb' );

{
    my ( $orig, $ref_to_orig, $copy_of_orig );
    no_leaks_ok {
        ( $orig, $ref_to_orig, $copy_of_orig ) = get_record();
    }
    'no leaks when getting a record';

    is_deeply(
        $orig,
        { ip => '1.1.1.1' },
        'got expected data in record'
    );

    is_deeply(
        $ref_to_orig->{ref},
        { ip => '1.1.1.1' },
        'got expected data in ref to record'
    );

    is_deeply(
        $copy_of_orig->{copy},
        { ip => '1.1.1.1' },
        'got expected data in copy of record'
    );

    no_leaks_ok {
        undef $reader;
    }
    'no leaks when destroying reader object';
}

done_testing();

sub get_record {
    my $orig = $reader->record_for_address('1.1.1.1');

    return (
        $orig,
        { ref  => $orig },
        { copy => { %{$orig} } },
    );
}

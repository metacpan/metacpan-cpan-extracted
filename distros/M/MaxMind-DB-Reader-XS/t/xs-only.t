use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;

use lib 't/lib';
use Test::MaxMind::DB::Reader;

use MaxMind::DB::Reader;

{
    my $filename = 'MaxMind-DB-test-ipv4-24.mmdb';
    my $reader   = MaxMind::DB::Reader->new(
        file => "maxmind-db/test-data/$filename" );

    isa_ok(
        $reader, 'MaxMind::DB::Reader::XS',
        'MaxMind::DB::Reader->new()'
    );

    my $metadata    = $reader->metadata;
    my $mmdb_record = $reader->record_for_address('1.1.1.32');

    $reader = undef;

    is_deeply(
        $mmdb_record,
        { ip => '1.1.1.32' },
        'string in entry data is still valid after mmdb free'
    );

    is(
        $metadata->description->{en},
        'Test Database',
        'string from metadata is still valid after mmdb free'
    );
}

{
    my $filename = 'MaxMind-DB-test-decoder.mmdb';
    my $reader   = MaxMind::DB::Reader->new(
        file => "maxmind-db/test-data/$filename" );

    my $mmdb_record = $reader->record_for_address('1.1.1.1');

    is(
        exception { $mmdb_record->{boolean} = 'foo' },
        undef,
        'returned boolean values are not read-only'
    );
}

done_testing();

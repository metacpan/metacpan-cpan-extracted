#!perl

use strict;
use warnings;

use Test::Most;
use JSON;
use JSON::DJARE::Writer;

my $writer = JSON::DJARE::Writer->new(
    djare_version => '0.0.2',
    meta_version  => '0.1.1',
    meta_from     => 0,
);

# Per the spec, some keys are expected to be strings, even if the Perl input
# was numeric

my $error = $writer->error_json(
    1,
    id     => 2,
    code   => 3,
    detail => 4,
    trace  => 5
);

like( $error, qr/"from":"0"/,   "from was stringified" );
like( $error, qr/"title":"1"/,  "title was stringified" );
like( $error, qr/"id":"2"/,     "id was stringified" );
like( $error, qr/"code":"3"/,   "code was stringified" );
like( $error, qr/"detail":"4"/, "detail was stringified" );

like( $error, qr/"trace":5/, "trace was correctly NOT stringified" );

my $data = $writer->data_json(6);
like( $data, qr/"data":6/, "data was correctly NOT stringified" );

done_testing();

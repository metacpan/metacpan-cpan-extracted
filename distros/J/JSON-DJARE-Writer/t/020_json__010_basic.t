#!perl

use strict;
use warnings;

use Test::Most;
use JSON;
use JSON::DJARE::Writer;

my $writer = JSON::DJARE::Writer->new(
    djare_version => '0.0.2',
    meta_version  => '0.1.1',
    meta_from     => 'foo',
);

for my $type (qw/data error/) {
    my $json_method = "${type}_json";
    my $minimal     = $writer->to_json( $writer->$type('foo') );

    is(
        $minimal,
        $writer->$json_method('foo'),
        "$type: Same result from both ways of getting json"
    );

    ok(
        ( exists decode_json($minimal)->{'meta'} )
          && ( exists decode_json($minimal)->{$type} ),
        "$type: sensible JSON produced"
    );
}

done_testing();
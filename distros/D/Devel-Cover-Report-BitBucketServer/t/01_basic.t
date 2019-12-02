use strict;
use warnings;

use Test::More;
use Path::Tiny qw(path);
use Devel::Cover::DB;
use JSON::MaybeXS qw(decode_json);

use_ok "Devel::Cover::Report::BitBucketServer";

chdir('t');

my $rfn = path('cover_db/bitbucket_server.json');
$rfn->remove;

ok( !$rfn->exists, 'start fresh' );

$ENV{DEVEL_COVER_DB_FORMAT} = 'JSON';

my $db    = Devel::Cover::DB->new( db => 'cover_db' );
my @files = sort $db->cover->items;

Devel::Cover::Report::BitBucketServer->report( $db, { file => \@files } );

ok( $rfn->exists, 'report generated' );

my $expect = {
    "files" => [
        {
            "coverage" =>
                'C:3,4,6,8,9,10,11,103,104,106,108,109,111,113,114,115,116,117,118,121,122,124,125,126,131,132,133,134,135,140,141,143,144,145,146,148;U:153,155,156,158,160,161,163,165,166,167,168,171,173;P:110,112,119,120,142',
            "path" => "lib/lib/archive.pm"
        },
    ],
};

my $got = decode_json( $rfn->slurp );

is_deeply( $got, $expect, 'content matches' );

done_testing();

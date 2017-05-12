use Test::Most;
use CHI;

use_ok('Google::Client::Files');
can_ok(
    'Google::Client::Files',
    qw/
    copy
    create
    create_media
    delete
    empty_trash
    export
    generate_ids
    get
    list
    update
    update_media
    watch
    /
);

use_ok('Google::Client::Collection');
ok my $client = Google::Client::Collection->new(
    cache => CHI->new(driver => 'Memory', global => 0),
    cache_key => 'file-client'
), 'ok built client';
ok my $files = $client->files, 'got files client';
is $files->base_url, 'https://www.googleapis.com/drive/v3/files', 'file client has correct base_url';

done_testing;

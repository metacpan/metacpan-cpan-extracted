use strict;
use Test::More;

require_ok 'MIME::DB';

ok(my $db = MIME::DB->data, 'data call');

## only test known and stable MIME types

# text/html
isa_ok($db->{'text/html'}, 'HASH', 'text/html entry');
isa_ok($db->{'text/html'}->{extensions}, 'ARRAY', 'extensions');
is(	(scalar grep {/^html$/} @{$db->{'text/html'}->{extensions}}), 1, 'extensions contain .html');
is($db->{'text/html'}->{compressible}, 1, 'type is compressible');

# video/mp4
isa_ok($db->{'video/mp4'}, 'HASH', 'video/mp4 entry');
isa_ok($db->{'video/mp4'}->{extensions}, 'ARRAY', 'extensions property');
is(	(scalar grep {/^mp4$/} @{$db->{'video/mp4'}->{extensions}}), 1, 'extensions contain .mp4');
is($db->{'video/mp4'}->{compressible}, 0, 'type is not compressible property');

# modifications
is_deeply($db, MIME::DB->data, "each call to data() generates a hash ith identical content");
ok($db != MIME::DB->data, "each call to data() generates an independant hash");

$db->{foo} = {};
delete $db->{'text/html'};
ok(!exists MIME::DB->data->{foo}, "local modifications do not affect other copies");
ok(exists MIME::DB->data->{'text/html'}, "local modifications do not affect other copies");

done_testing();
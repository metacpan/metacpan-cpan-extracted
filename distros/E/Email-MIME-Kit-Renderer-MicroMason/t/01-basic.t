use strict;
use warnings;

use Test::More tests => 2;
use Email::MIME::Kit;

my $kit = Email::MIME::Kit->new( { source => 't/kits/test.mkit', } );

my $email = $kit->assemble( {
        name  => 'joe smith',
        email => 'joe@nowhere.x',
} );

like(
    $email->body,
    qr{\QHi there joe smith},
    'micromason in manifest body worked'
);

is(
    $email->header('Subject'),
    'Welcome aboard, joe smith',
    'micromason in subject worked'
);

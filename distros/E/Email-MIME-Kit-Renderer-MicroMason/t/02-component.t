use strict;
use warnings;

use Test::More tests => 4;
use Email::MIME::Kit;

my $kit = Email::MIME::Kit->new( { source => 't/kits/include.mkit', } );

my $email = $kit->assemble( {
        name  => 'joe smith',
        email => 'joe@nowhere.x',
} );

is(
    $email->header('Subject'),
    'Welcome aboard, joe smith',
    'micromason in subject worked'
);

like( $email->body, qr{\QWelcome to WY}, 'micromason in body worked' );
like( $email->body, qr{\QDear joe smith},
    'micromason header component worked' );
like( $email->body, qr{\QManagement}, 'micromason footer component worked' );

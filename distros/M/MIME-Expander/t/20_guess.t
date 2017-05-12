use strict;
use Test::More tests => 1;
use MIME::Expander::Guess;
is( MIME::Expander::Guess->type( \ "foo"), 'application/octet-stream', 'type' );

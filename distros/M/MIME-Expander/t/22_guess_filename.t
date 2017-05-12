use strict;
use Test::More tests => 7;
use MIME::Expander::Guess::FileName;

is( MIME::Expander::Guess::FileName->type( \ "foo"), undef, 'type' );

is( MIME::Expander::Guess::FileName->type( \ "foo", {
        filename => 'no_suffix',
    }), undef, 'type no_suffix' );

is( MIME::Expander::Guess::FileName->type( \ "foo", {
        filename => 'text.txt',
    }), 'text/plain', 'type text' );

like( MIME::Expander::Guess::FileName->type( \ "foo", {
        filename => 'data.zip',
    }), qr'application/(x-)?zip', 'type zip' );

like( MIME::Expander::Guess::FileName->type( \ "foo", {
        filename => 'data.gz',
    }), qr'application/(x-)?gzip', 'type gzip' );

like( MIME::Expander::Guess::FileName->type( \ "foo", {
        filename => 'data.tar.gz',
    }), qr'application/(x-)?gnutar', 'type tar gzip' );

like( MIME::Expander::Guess::FileName->type( \ "foo", {
        filename => 'data.tar',
    }), qr'application/(x-)?tar', 'type tar' );


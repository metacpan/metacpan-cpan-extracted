use strict;
use warnings;

use Test::More;
use Test::Exception;
use MIME::Base64;

use Image::Empty;

my $gif;

lives_ok { $gif = Image::Empty->gif } "instantiated gif ok";

ok( $gif->type eq 'image/gif', "type" );

ok( $gif->length == 43, "length" );

ok( $gif->disposition eq 'inline', "disposition" );

ok( $gif->filename eq 'empty.gif', "filename" );

my $output = $gif->render;

my $static = 'Content-Type: ' . 'image/gif' . "\015\012" .
	       'Content-Length: ' . 43 . "\015\012" .
	       'Content-Disposition: ' . 'inline' . '; filename="' . 'empty.gif' . '"' . "\015\012" . 
	       "\015\012" . decode_base64('R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==');
    
ok( $output eq $static, "rendered output looks good" );

done_testing();

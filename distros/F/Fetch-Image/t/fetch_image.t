use strict;
use warnings;

use Test::More;
use Test::Exception;

use Fetch::Image;

diag("these tests will fail without an active internet connection, that's not my fault!");

my $fetcher_config = {
    'max_filesize' => '51200',
    'user_agent' => 'mozilla firefox yo',
};

my $fetcher = new_ok('Fetch::Image' => [$fetcher_config], 'fetcher');

# text file
throws_ok{
    $fetcher->fetch( 'http://www.ietf.org/rfc/rfc3751.txt' );
} qr/invalid content-type/, 'not an image';

# large file (50k+)
throws_ok{
    $fetcher->fetch( 'http://i.zdnet.com/blogs/nasa-small.bmp' );
} qr/filesize exceeded/, 'file too large';

# invalid url
throws_ok{
    $fetcher->fetch( 'something un urlish' );
} qr/invalid url/, 'invalid url';

# 404 - test uri encode (doesn't throw "invalid url" error)
throws_ok{
    $fetcher->fetch( 'http://www.google.com/file isnt real' );
} qr/transfer error/, 'error 404';

# 404 - test uri encode (doesn't throw "invalid url" error)
throws_ok{
    $fetcher->fetch( 'http://www.google.com/file%20isnt%20real' );
} qr/transfer error/, 'error 404';

# 404
throws_ok{
    $fetcher->fetch( 'http://www.google.com/fileisntreal' );
} qr/transfer error/, 'error 404';

# proper image
{
    my $image_info;
    lives_ok { $image_info = $fetcher->fetch( 'http://www.google.com/images/srpr/logo4w.png' ) } 'proper image';
    isa_ok( $image_info->{'temp_file'}, 'File::Temp', 'image isa tempfile' );
    is( $image_info->{'file_ext'}, 'png', 'correct filetype' );
}

# save fake temp (should never happen)
{
    my $ua = $fetcher->_setup_ua('http://www.google.com/robots.txt');
    throws_ok{
        ok( $fetcher->_save($ua, 'http://www.google.com/robots.txt'), 'download to Temp::File');
    } qr/not an image/, 'not an image';
}

# test allowed_types
{
    my $fetcher_config = {
        'allowed_types' => {
            'image/jpeg' => 1,
        },
    };
    my $fetcher = new_ok('Fetch::Image' => [$fetcher_config], 'fetcher');
    throws_ok{
        $fetcher->fetch('http://www.google.com/images/srpr/logo4w.png');
    } qr/invalid content-type/, 'invalid content-type';
}

done_testing;

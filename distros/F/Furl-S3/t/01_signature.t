use strict;
use Test::More;
use Furl::S3;
use URI::Escape;
use HTTP::Date;

# http://docs.amazonwebservices.com/AmazonS3/latest/dev/index.html?RESTAuthentication.html
my $s3 = Furl::S3->new(
    aws_access_key_id => '0PN5J17HBGZHT7JJ3X82',
    aws_secret_access_key => 'uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o',
);

{
    my $date = time2str( time );
    my $resource = '/foo/bar/baz.jpg';
    my $string_to_sign = $s3->string_to_sign('GET', $resource, {
        date => $date,
    });

    my $expected = 
        "GET\n". 
        "\n". 
        "\n". 
        "$date\n". 
        $resource;

    is $string_to_sign, $expected, 'GET';
}

{
    my $date = time2str( time );
    my $resource = '/foo/bar-baz.txt';
    # encode_base64(md5('hoge'));
    my $md5 = '6nA+eqHv2gBk6qUH2eirfg==';
    my $content_type = 'text/plain';
    my $string_to_sign = $s3->string_to_sign('PUT', $resource, {
        'content-type' => $content_type,
        'content-md5' => $md5,
        'x-amz-acl' => 'public-read',
        date => $date,
    });

    my $expected = 
        "PUT\n". 
        "$md5\n". 
        "$content_type\n". 
        "$date\n". 
        "x-amz-acl:public-read\n". 
        $resource;
    is $string_to_sign, $expected, 'PUT';
}

{
    my $string_to_sign = 
        "PUT\n".
        "4gJE4saaMU4BqNR0kLY+lw==\n".
        "application/x-download\n".
        "Tue, 27 Mar 2007 21:06:08 +0000\n".
        "x-amz-acl:public-read\n".
        "x-amz-meta-checksumalgorithm:crc32\n".
        "x-amz-meta-filechecksum:0x02661779\n".
        "x-amz-meta-reviewedby:joe\@johnsmith.net,jane\@johnsmith.net\n".
        "/static.johnsmith.net/db-backup.dat.gz";
    is $s3->sign( $string_to_sign ), 'C0FlOtU8Ylb9KDTpZqYkZPX91iI=';
}

{
    my $expires = time + 10;
    my $string_to_sign = $s3->string_to_sign('GET', '/foo/bar-baz.txt', {
        expires => $expires,
    });
    my $sig = uri_escape( $s3->sign( $string_to_sign ) );
    my $url = $s3->signed_url('foo', 'bar-baz.txt', $expires);
    like $url, qr/Expires=$expires/;
    like $url, qr/foo\.s3.amazonaws\.com/;
    like $url, qr/Signature=$sig/;
}



done_testing;

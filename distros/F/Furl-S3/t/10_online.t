
use strict;
use Test::More;
use Furl::S3;
use Furl;

unless ( $ENV{TEST_AWS_ACCESS_KEY_ID} && $ENV{TEST_AWS_SECRET_ACCESS_KEY} ) {
    plan skip_all => 'online tests are skipped';
}

my $s3 = Furl::S3->new(
    aws_access_key_id => $ENV{TEST_AWS_ACCESS_KEY_ID},
    aws_secret_access_key => $ENV{TEST_AWS_SECRET_ACCESS_KEY},
    secure => 0,
);
my $bucket = $ENV{TEST_S3_BUCKET} || lc('test-'. $ENV{TEST_AWS_ACCESS_KEY_ID}. '-'. time);

{
    my $res = $s3->list_buckets;
    ok $res->{owner}{id}, 'list_buckets';
}

{
    my $res = $s3->list_objects( $bucket, {
        'max-keys' => 0,
    });
    if ( $res ) {
        plan skip_all => "Bucket $bucket is already exists";
    }
}

{
    ok $s3->create_bucket( $bucket ), 'create_bucket';
    my $res = $s3->list_objects( $bucket );
    is $res->{name}, $bucket, 'list_objects';
    ok !@{$res->{contents}}, 'no objects';
}

{
    my $str = time;
    ok $s3->create_object($bucket, 'foo.txt', $str, +{
        'x-amz-meta-foo' => 'bar',
        content_type => 'text/plain',
    }), 'create_object with meta data';

    my $res = $s3->get_object($bucket, 'foo.txt');
    ok $res, 'get_object';
    is $res->{content}, $str, 'content';
    is $res->{content_type}, 'text/plain', 'content_type';
    is $res->{content_length}, length($str), 'content_length';
    is $res->{'x-amz-meta-foo'}, 'bar', 'meta data';

    my $signed_url = $s3->signed_url( $bucket, 'foo.txt', time + 5 );
    my $furl = Furl->new;

    {
        my $res = $furl->get( $signed_url );
        is $res->code, '200', 'get signed url. ok';
        is $res->content, $str, 'get signed url';;
    }

    # expired request.
    sleep 6;
    {
        my $res = $furl->get( $signed_url );
        is $res->code, '403', 'get signed url. forbidden';
    }
}

{
    my $res = $s3->head_object( $bucket, 'foo.txt' );
    is $res->{'x-amz-meta-foo'}, 'bar', 'head_object';
}

{
    open my $fh, './t/TEST.txt';
    ok $s3->create_object($bucket, 'TEST.txt', $fh), 'create_object from FileHandle';
    close $fh;
    my $res = $s3->get_object($bucket, 'TEST.txt');
    like $res->{content}, qr/^TEST_DOCUMENT/, 'get_object';
}

# get_object and writ_code
{
    my $content;
    my $res = $s3->get_object($bucket, 'TEST.txt', {}, {
        write_code => sub {
            my( $code, $message, $headers, $buf ) = @_;
            is $code, 200, 'write_code callback';
            $content .= $buf;
        },
    });
    is $res->{content}, undef, 'get_object response with write_code';
    like $res->{etag}, qr/^[a-f0-9]{32}$/, 'etag';
    like $content, qr/^TEST_DOCUMENT/, 'write_code callback';
}

# create_object_from_file
{
    ok $s3->create_object_from_file($bucket, 'test.jpg', './t/test.jpg'), 'create_object_from_file';
    my $res = $s3->get_object($bucket, 'test.jpg');
    is $res->{content_type}, 'image/jpeg';
}


{
    my $filename = './t/download.txt';
    ok $s3->get_object_to_file( $bucket, 'TEST.txt', $filename ), 'get_object_to_file';
    local $/ = undef;
    open my $fh, '<', $filename;
    my $content = <$fh>;
    close $fh;
    like $content, qr/^TEST_DOCUMENT/, 'get_object_to_file ';
    unlink $filename;
}


{
    # can not delete.
    ok !$s3->delete_bucket( $bucket );
    isa_ok $s3->error, 'Furl::S3::Error';
    is $s3->error->http_code, 409, 'Conflict';
}

{
    my $res = $s3->list_objects( $bucket );
    ok !$s3->error, 'clear_error';
    is @{$res->{contents}}, 3;
    for my $obj(@{$res->{contents}}) {
        like $obj->{etag}, qr/^[a-f0-9]{32}$/, 'etag';
        like $obj->{key}, qr/^(foo\.txt|TEST\.txt|test\.jpg)$/, 'check objects';
        $s3->delete_object( $bucket, $obj->{key} );
    }
}

# multi-byte
{
    use utf8;
    my $str = time;
    my $key = 'ほげ/ほげ ほげ.txt';
    ok $s3->create_object($bucket, $key, $str, +{
        content_type => 'text/plain',
    }), 'create_object multi-byte key name';

    my $res = $s3->get_object($bucket, $key);
    ok $res, 'get_object';
    is $res->{content}, $str, 'content';
    is $res->{content_type}, 'text/plain', 'content_type';
    is $res->{content_length}, length($str), 'content_length';


    my $key2 = 'あいうえお.txt';
    ok $s3->copy_object( $bucket, $key, $bucket, $key2 ), 'copy_object';
    ok $s3->delete_object( $bucket, $key ), 'delete old file';

    $res = $s3->get_object($bucket, $key2);
    ok $res, 'get_object';
    is $res->{content}, $str, 'content';

    $s3->delete_object( $bucket, $key2 );
}


ok $s3->delete_bucket( $bucket );


done_testing();

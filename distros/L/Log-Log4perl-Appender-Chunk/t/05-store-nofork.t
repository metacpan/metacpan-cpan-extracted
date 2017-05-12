#! perl -T
use Test::More;

use Log::Log4perl;

use Data::UUID;
my $ug =  new Data::UUID;

my $uuid = lc($ug->create_str());

my $access_key_id = $ENV{AWS_ACCESS_KEY_ID} || 'A-Fake-keyID';
my $access_key_secret = $ENV{AWS_ACCESS_KEY_SECRET} || 'A-Fake-Secret-Key';

my $conf = q|
log4perl.rootLogger=TRACE, Chunk

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%m%n

log4perl.appender.Chunk=Log::Log4perl::Appender::Chunk
log4perl.appender.Chunk.store_class=S3
log4perl.appender.Chunk.store_args.bucket_name=cpan-jeteve-eu-|.$uuid.q|
log4perl.appender.Chunk.store_args.host=s3-eu-west-1.amazonaws.com
log4perl.appender.Chunk.store_args.location_constraint=EU
log4perl.appender.Chunk.store_args.aws_access_key_id=|.$access_key_id.q|
log4perl.appender.Chunk.store_args.aws_secret_access_key=|.$access_key_secret.q|
log4perl.appender.Chunk.store_args.expires_in_days=3
log4perl.appender.Chunk.store_args.with_forking=0
log4perl.appender.Chunk.store_args.acl_short=public-read
log4perl.appender.Chunk.store_args.retry=1
log4perl.appender.Chunk.store_args.vivify_bucket=1

log4perl.appender.Chunk.layout=${layout_class}
log4perl.appender.Chunk.layout.ConversionPattern=${layout_pattern}
|;

Log::Log4perl::init(\$conf);

ok( my $ca =  Log::Log4perl->appender_by_name('Chunk') , "Ok got Chunk appender");
ok( my $store = $ca->store() , "Ok got store for the logger");
ok( $store->s3_client() , "Ok got s3 client");
ok( $store->_expiry_ymd() , "Ok got expiry YMD");
ok( $store->acl_short() , "Ok got acl_short");
is( $store->host(), 's3-eu-west-1.amazonaws.com' );
is( $store->with_forking() , 0 );
is( $store->location_constraint(),  'EU' );

my $clone = $store->clone();
ok( $clone->s3_client() , "Ok got s3 client");
ok( $clone->_expiry_ymd() , "Ok got expiry YMD");
ok( $clone->acl_short() , "Ok got acl_short");
is( $clone->host(), 's3-eu-west-1.amazonaws.com' );
is( $clone->location_constraint(),  'EU' );
is( $clone->with_forking() , 0 );


SKIP:{
    unless( $ENV{AMAZON_S3_EXPENSIVE_TESTS} ){
        skip q/No AMAZON_S3_EXPENSIVE_TESTS=1 in the environment. Skipping side effect test.

Also, you will want to set AWS_ACCESS_KEY_ID, AWS_ACCESS_KEY_SECRET AWS_BUCKET in the environment.

Test buckets will be prefixed with JETEVE-FullMetalBucket-

/, 2 ;
    }
    # This SHOULD NOT fork.
    ok( $store->store('a_key' , 'Some big content'), "Ok can store stuff");

    ok( my $bucket = $store->bucket() );

    # Do some cleanup:
    if( $bucket ){
        $bucket->object( key => 'a_key' )->delete();
        $bucket->delete();
    }
}


done_testing();

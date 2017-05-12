use strict;
use Test::More;
use Furl::S3;

{
    local $@;
    eval {
        my $s3 = Furl::S3->new;
    };
    like $@, qr/Mandatory parameters/, 'new';
    ok $@;
}

{
    my $s3 = Furl::S3->new(
        aws_access_key_id => 'x',
        aws_secret_access_key => 'x',
    );
    {
        for my $method(qw(create_bucket delete_bucket create_object delete_bucket)) {
            local $@;
            eval {
                $s3->$method();
            };
            like $@, qr/0 parameters/;
        }
    }

}

{
    ok !Furl::S3::validate_bucket('###');
    ok Furl::S3::validate_bucket('foo.bar');
    ok Furl::S3::is_dns_style('foo-bar');
    ok !Furl::S3::is_dns_style('foo-bar-');
    ok !Furl::S3::is_dns_style('foo..bar');
    ok !Furl::S3::is_dns_style('foo.bar.baz-');
}

done_testing;

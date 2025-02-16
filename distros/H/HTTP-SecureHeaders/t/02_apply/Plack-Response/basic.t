use Test2::V0;
use Test2::Require::Module 'Plack::Response';

use lib qw(./t/lib);

use HTTPSecureHeadersTestApply;

subtest 'Tests on Plack::Response' => sub {

    local $HTTPSecureHeadersTestApply::DATA_HEADERS = sub {
        my ($headers) = @_;
        my %data = map {
            my $k = $_;
            map {
                ( $k => $_ )
            } $headers->header($k);
        } $headers->header_field_names;

        return \%data;
    };

    local $HTTPSecureHeadersTestApply::CREATE_HEADERS = sub {
        my $res = Plack::Response->new;
        $res->headers(\@_);
    };

    HTTPSecureHeadersTestApply::main();
};

done_testing;

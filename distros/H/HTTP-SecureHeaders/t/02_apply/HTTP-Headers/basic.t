use Test2::V0;
use Test2::Require::Module 'HTTP::Headers';

use lib qw(./t/lib);

use HTTPSecureHeadersTestApply;

subtest 'Tests on HTTP::Headers' => sub {

    local $HTTPSecureHeadersTestApply::DATA_HEADERS = sub {
        my ($headers) = @_;
        my %data = $headers->flatten;
        return \%data;
    };

    local $HTTPSecureHeadersTestApply::CREATE_HEADERS = sub {
        HTTP::Headers->new(@_)
    };

    HTTPSecureHeadersTestApply::main();
};

done_testing;

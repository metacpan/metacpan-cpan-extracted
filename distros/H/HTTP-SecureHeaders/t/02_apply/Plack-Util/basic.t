use Test2::V0;
use Test2::Require::Module 'Plack::Util';

use lib qw(./t/lib);

use HTTPSecureHeadersTestApply;

subtest 'Tests on Plack::Util::headers' => sub {

    local $HTTPSecureHeadersTestApply::DATA_HEADERS = sub {
        my ($headers) = @_;
        my %data = @{$headers->headers};
        return \%data;
    };

    local $HTTPSecureHeadersTestApply::CREATE_HEADERS = sub {
        my (@args) = @_;
        Plack::Util::headers(\@args);
    };

    HTTPSecureHeadersTestApply::main();
};

done_testing;

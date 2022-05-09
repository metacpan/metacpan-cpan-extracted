use strict;
use warnings;
use Test::More;
use Test::Requires qw(
    HTTP::Headers::Fast
);

use lib qw(./t/lib);

use HTTPSecureHeadersTestApply;

subtest 'Tests on HTTP::Headers::Fast' => sub {

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
        HTTP::Headers::Fast->new(@_)
    };

    HTTPSecureHeadersTestApply::main();
};

done_testing;

package InternetDataTest;

use strict;
use warnings;

use Mojo::File 'path';
use Mojo::JSON qw(decode_json false);

# The language-neutral conformance corpus, generated into every InternetData SDK
# so a binding that drifts fails its own suite.
sub corpus {
    my $root = path(__FILE__)->to_abs->dirname->dirname->dirname;
    return decode_json($root->child('testdata', 'testdata.json')->slurp);
}

# One licensed family in the shape /api/v2/database/list answers, so a test can
# vary the one field it is about rather than restating the whole document.
sub family {
    my (%overrides) = @_;
    return {
        base => 'bogon_ip',
        name => 'Bogon IP',
        summary => 'IP ranges that cannot legitimately appear on the internet.',
        standing => 'licensed',
        open => false,
        license_type => 'standard',
        starts => '2026-09-04T07:49:45.118Z',
        expires => undef,
        versions => [{
            id => 'bogon_ip_v1',
            version => 1,
            summary => 'IP ranges that cannot legitimately appear on the internet.',
            formats => ['csvgz', 'mmdb'],
        }],
        %overrides,
    };
}

1;

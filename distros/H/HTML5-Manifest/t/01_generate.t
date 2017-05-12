use strict;
use warnings;
use Test::More;

use File::Spec;
use HTML5::Manifest;

my $manifest = HTML5::Manifest->new(
    use_digest => 1,
    htdocs     => File::Spec->catfile('t', 'htdocs'),
    skip       => [
        qr{^temporary/},
        qr{\.svn/},
        qr{\.swp$},
        qr{\.txt$},
        qr{\.html$},
        qr{\.cgi$},
    ],
    network => [
        '/api',
        '/foo/bar.cgi',
    ],
);

is($manifest->generate, <<MANIFEST);
CACHE MANIFEST

NETWORK:
/api
/foo/bar.cgi

CACHE:
/cache.js
/css/site.css
/dispatcher.js

# digest: JYcyuHljtQxhQLUcYJ6MTw
MANIFEST

done_testing;

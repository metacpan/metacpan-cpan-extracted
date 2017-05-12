use strict;
use warnings;

use Test::More tests => 4;
use Digest::MD5 qw(md5_hex);

my %MD5_FOR = (
    'style.css'      => '8b7164f64651ea7abed61131a749d7b0',
    'background.gif' => '01d4003e8bf0191d38ff170f613e47f0',
);

BEGIN { use_ok('HTTP::CDN') };

# dynamic init
my $cdn = HTTP::CDN->new(
    root => 't/data',
    base => 'cdn/',
);

# static init
eval { $cdn->resolve('404.pants'); };
like($@, qr/^Failed to stat/);

eval { $cdn->resolve(); };
like($@, qr/No URI specified/);

eval { $cdn->resolve('404.css'); };
like($@, qr/^Failed to stat/);


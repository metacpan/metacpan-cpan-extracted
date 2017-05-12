use 5.010;
use strict;
use warnings;

use Test::More;
use HTTP::CDN;

my $cdn = HTTP::CDN->new(
    root => 't/data',
    base => 'cdn/',
);

my $stylesheet = $cdn->filedata('style2.css');
#diag($stylesheet);
my @links = $stylesheet =~ m{url\((.*?)\)}sg;

my $hash = "[0-9A-F]{12}";
like shift @links, qr{^inc[.]$hash[.]css$},           'bare url';
like shift @links, qr{^'inc[.]$hash[.]css'$},         'single quotes';
like shift @links, qr{^"inc[.]$hash[.]css"$},         'double quotes';
like shift @links, qr{^"inc[.]$hash[.]css"$},         'leading ./ stripped';
like shift @links, qr{^inc[.]$hash[.]css$},           'whitespace stripped';
like shift @links, qr{^inc[.]$hash[.]css$},           'more whitespace stripped';
like shift @links, qr{^inc[.]$hash[.]css\?query$},    'with querystring';
like shift @links, qr{^inc[.]$hash[.]css\#hash$},     'with hash fragment';
like shift @links, qr{^inc[.]$hash[.]css\?\#iefix$},  'with queryhack';

done_testing;

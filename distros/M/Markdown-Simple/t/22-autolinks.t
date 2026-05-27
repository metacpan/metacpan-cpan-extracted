use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

# Autolinks <http://x>. CommonMark §6.5.
md_like( '<http://example.com>',
    qr|<a href="http://example\.com">http://example\.com</a>|,
    'URL autolink' );
md_like( '<https://example.com/x?y=1>',
    qr|<a href="https://example\.com/x\?y=1">https://example\.com/x\?y=1</a>|,
    'URL autolink with query' );
md_like( '<user@example.com>',
    qr|<a href="mailto:user\@example\.com">user\@example\.com</a>|,
    'email autolink' );

done_testing;

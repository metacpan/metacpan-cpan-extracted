use strict;
use warnings;
use utf8;

use Test::More;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

my @fragments = (
    [
'<p lang="foo">Supercalifragilisticexpialidocious</p>',
'<p lang="foo">Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious</p>',
        'custom foo language'
    ],
);

plan tests => ( 0 + @fragments ) + 1;

use HTML::Hyphenate;
use TeX::Hyphen;
my $h = HTML::Hyphenate->new();
my $t = TeX::Hyphen->new();
$h->register_tex_hyphen('foo', $t);
foreach my $frag (@fragments) {
    is( $h->hyphenated( @{$frag}[0] ), @{$frag}[1], @{$frag}[2] );
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();

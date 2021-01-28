use strict;
use warnings;
use utf8;
use Test::More;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };
use Test::Warn;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my @fragments = (
    [
'<p lang="en-US-x-Hixie">Supercalifragilisticexpialidocious</p>',
'<p lang="en-US-x-Hixie">Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious</p>',
        'lang en-US-x-Hixie'
    ],
    [
'<p lang="ae-AE-x-Hixie">Supercalifragilisticexpialidocious</p>',
'<p lang="ae-AE-x-Hixie">Supercalifragilisticexpialidocious</p>',
        'non-existing lang ae-AE-x-Hixie for coverage'
    ],
);

plan tests => ( 0 + @fragments ) + 1;

use HTML::Hyphenate;
my $h = HTML::Hyphenate->new();
foreach my $frag (@fragments) {
	is( $h->hyphenated( @{$frag}[0] ), @{$frag}[1], @{$frag}[2] );
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
if ($ENV{AUTHOR_TESTING}) {
	Test::NoWarnings::had_no_warnings();
}

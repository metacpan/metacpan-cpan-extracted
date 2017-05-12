#!/usr/bin/perl

# Test that the syntax of our POD documentation is valid
use strict;
BEGIN
{
    $|  = 1;
    $^W = 1;

    use Test::More;
    unless ($ENV{AUTHOR_TESTING})
    {
        plan skip_all => "Author tests not required for installation";
    }
    else
    {
        eval "use Test::Pod::Coverage;";
    }
}

plan tests => 1;

pod_coverage_ok('Image::Size' => { also_private => [ qr/size$/, 'img_eof' ] },
                'Image::Size');

exit;

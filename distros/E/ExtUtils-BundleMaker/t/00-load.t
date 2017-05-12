#!perl -T

use Test::More tests => 1;

BEGIN
{
    use_ok('ExtUtils::BundleMaker') || BAIL_OUT "Couldn't load ExtUtils::BundleMaker!";
}

diag("Testing ExtUtils::BundleMaker $ExtUtils::BundleMaker::VERSION, Perl $], $^X");

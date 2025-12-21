#!perl
use 5.006;
use Test::More;
use ExtUtils::Manifest;

SKIP: {
    skip "Author tests not required for installation"
        unless $ENV{RELEASE_TESTING};
    is_deeply [ExtUtils::Manifest::manicheck()], [], 'missing';
    is_deeply [ExtUtils::Manifest::filecheck()], [], 'extra';
}

done_testing;

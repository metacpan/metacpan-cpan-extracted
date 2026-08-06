#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

unless ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}) {
  plan(skip_all => 'Author/Release tests not required for installation');
}

eval 'use Test::CPAN::Changes';
plan(skip_all => 'Test::CPAN::Changes required for testing changelog format')
  if $@;

changes_ok();

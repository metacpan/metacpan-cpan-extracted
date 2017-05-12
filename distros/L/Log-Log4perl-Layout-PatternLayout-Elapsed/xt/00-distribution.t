use Test::More;

eval 'use Test::Distribution not => ["sig", "prereq"]';
plan( skip_all => 'Test::Distribution not installed') if $@;

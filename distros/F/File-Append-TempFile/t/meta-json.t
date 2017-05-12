# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl meta-json.t'

use Test::More;
eval 'use Test::CPAN::Meta::JSON';
plan skip_all => 'Test::CPAN::Meta::JSON not found' if $@;
meta_json_ok();

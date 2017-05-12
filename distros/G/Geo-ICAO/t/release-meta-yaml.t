#!perl
# 
# This file is part of Geo-ICAO
# 
# This software is copyright (c) 2007 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use Test::More;

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;
meta_yaml_ok();
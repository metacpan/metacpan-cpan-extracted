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
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use Test::More;
use English qw(-no_match_vars);

eval "use Test::Perl::Critic";
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok();
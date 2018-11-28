use v5.28.0;
use lib 't/lib';
use strict;
use warnings;
use Hailo::Test;
use Test::More;

plan skip_all => "You need the optional DBD::mysql module for MySQL support" unless eval "require DBD::mysql;";

Hailo::Test->new( storage => 'MySQL' )->test_all_plan;

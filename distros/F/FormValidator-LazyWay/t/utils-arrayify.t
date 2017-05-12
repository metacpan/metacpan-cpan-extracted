use strict;
use warnings;
use Test::More qw/no_plan/;
use FormValidator::LazyWay::Utils;
use utf8;

is_deeply( [FormValidator::LazyWay::Utils::arrayify( )] , [()] ); 
is_deeply( [FormValidator::LazyWay::Utils::arrayify([])] , [()] ); 
is_deeply( [FormValidator::LazyWay::Utils::arrayify([qw/foo bar/])] , [qw/foo bar/] ); 
is_deeply( [FormValidator::LazyWay::Utils::arrayify('foo')] , [qw/foo/] ); 


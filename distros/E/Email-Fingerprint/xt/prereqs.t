use Test::More;

eval "use Test::Prereq";
plan skip_all => "Test::Prereq required to test dependencies" if $@;

prereq_ok('5.007003', 'Makefile prerequisites', [qw{ t/eliminate_dups.pl }]);

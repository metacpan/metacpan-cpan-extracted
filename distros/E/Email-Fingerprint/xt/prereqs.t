use Test::More;

eval "use Test::Prereq";
plan skip_all => "Test::Prereq required to test dependencies" if $@;

prereq_ok('Makefile prerequisites', [qw{
    lib strict warnings English POSIX
}]);

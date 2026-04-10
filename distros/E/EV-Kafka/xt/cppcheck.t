use strict;
use warnings;
use Test::More;

plan skip_all => 'set CPPCHECK_TEST to run' unless $ENV{CPPCHECK_TEST};
plan skip_all => 'cppcheck not found' unless `which cppcheck 2>/dev/null`;

plan tests => 1;

my $out = `cppcheck --enable=warning,performance --error-exitcode=1 --quiet --suppress=missingIncludeSystem --suppress=unknownMacro --suppress=preprocessorErrorDirective --suppress=missingInclude src/EV__Kafka.xs 2>&1`;
my $rc = $? >> 8;

if ($rc != 0) {
    fail 'cppcheck found issues';
    diag $out;
} else {
    pass 'cppcheck clean';
}

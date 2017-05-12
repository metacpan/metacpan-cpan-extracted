use inc::Module::Install;
name 'HTTP-Response-Parser';
all_from 'lib/HTTP/Response/Parser.pm';

cc_warnings;
use_ppport;

test_requires 'Test::More';
test_requires 'HTTP::Response';

makemaker_args(
    clean => {
        FILES => q{
            *.stackdump
            *.gcov *.gcda *.gcno
            *.out
            nytprof
            cover_db
        },
    },
);

tests 't/*.t';
# author_tests 'xt';

repository 'git://github.com/mala/HTTP-Response-Parser.git';

WriteAll;

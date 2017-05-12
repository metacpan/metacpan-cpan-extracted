use inc::Module::Install;

name     'Lingua-JA-Halfwidth-Katakana';
all_from 'lib/Lingua/JA/Halfwidth/Katakana.pm';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => 0.88; # done_testing
test_requires 'Test::Base';

readme_from 'lib/Lingua/JA/Halfwidth/Katakana.pm';

resources(
    license    => 'http://dev.perl.org/licenses',
    repository => 'https://github.com/pawa-/Lingua-JA-Halfwidth-Katakana',
    bugtracker => 'https://github.com/pawa-/Lingua-JA-Halfwidth-Katakana/issues',
);

WriteAll;

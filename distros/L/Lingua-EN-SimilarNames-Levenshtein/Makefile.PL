use inc::Module::Install;

name 'Lingua-EN-SimilarNames-Levenshtein';

all_from 'lib/Lingua/EN/SimilarNames/Levenshtein.pm';

abstract 'Compare Names for Similar Spelling';
author 'Mateu X Hunter';
license 'perl';
version_from 'lib/Lingua/EN/SimilarNames/Levenshtein.pm';

requires(
    'MooseX::Declare'        => 0,
    'Text::LevenshteinXS'    => 0,
    'Math::Combinatorics'    => 0,
);

test_requires 'Test::Leaner' => 0;

WriteAll;

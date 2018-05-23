use strict;
use warnings;

use lib './inc';

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Math::GrahamFunction',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/Math/GrahamFunction.pm',
    configure_requires => { 'Module::Build' => '0.39', },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Class::Accessor' => 0,
        'List::Util' => 0,
        'perl' => '5.008',
    },
    add_to_cleanup      => [ 'Math::GrahamFunction-*' ],
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/perl-math-grahamfunction/",
        },
        keywords =>
        [
            "factors",
            "fun",
            "function",
            "graham",
            "math",
            "mathematics",
            "maths",
            "mjd",
            "obscure",
            "pure-perl",
            "riddle",
            "riddles",
            "quizzes",
            "qotw",
            "quiz",
            "quiz-of-the-week",
            "square",
            "week",
        ],
    },
);

$builder->create_build_script();

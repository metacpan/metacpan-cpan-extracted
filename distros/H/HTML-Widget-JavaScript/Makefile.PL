use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::Widget::JavaScript',
    AUTHOR              => 'Nilson Santos Figueiredo Júnior <nilsonsfj@cpan.org>',
    VERSION_FROM        => 'lib/HTML/Widget/JavaScript.pm',
    ABSTRACT_FROM       => 'lib/HTML/Widget/JavaScript.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'HTML::Widget' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-Widget-JavaScript-*' },
);

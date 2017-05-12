use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::FillInForm',
    'VERSION_FROM'	=> 'lib/HTML/FillInForm.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	HTML::Parser => 3.26,
	HTML::TokeParser => 3.26,
        warnings => 0
    },
    TEST_REQUIRES => {
        CGI => 0
    },
    META_MERGE		=> {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/markstos/HTML-FillInForm.git',
                web  => 'https://github.com/markstos/HTML-FillInForm',
            },
        },
    },
);

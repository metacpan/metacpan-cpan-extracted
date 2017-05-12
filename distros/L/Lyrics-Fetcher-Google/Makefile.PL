use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Lyrics::Fetcher::Google',
    AUTHOR       => 'John Lifsey <nebulous@crashed.net>',
    VERSION	 => '0.02',    
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Lyrics::Fetcher' => '0.3.1',
                     'Net::Google' => '0.53',
                     'LWP::UserAgent' => undef,
                     'HTML::LinkExtractor' => undef,
                     'HTML::TokeParser::Simple' => undef,
                     'String::Similarity' => undef,
                    },
);

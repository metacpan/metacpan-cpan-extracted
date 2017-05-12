use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'HTTP::OAIPMH::Validator',
    AUTHOR        => 'Simeon Warner <simeon@cpan.org>',
    ABSTRACT      => 'OAI-PMH Validator used for http://www.openarchives.org/pmh/validate',
    VERSION_FROM  => 'lib/HTTP/OAIPMH/Validator.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    PREREQ_PM => {
        'Class::Accessor::Fast' => 0.34,
        'Date::Manip' => 6.48,
        'Data::UUID' => 1.22,
        'HTTP::Request' => 6.00,
        'HTTP::Headers' => 6.05,
        'HTTP::Request::Common' => 6.04,
        'HTTP::Status' => 6.03,
        'JSON' => 2.9,
        'LWP::UserAgent' => 6.06,
        'LWP::Protocol::https' => 6.06, # https support
        'Crypt::SSLeay' => 0.72, # for Net::SSL
        'Try::Tiny' => 0.19,
        'URI::Escape' => 3.31,
        'XML::DOM' => 1.44,
        'CGI' => 3.50,
    },
    BUILD_REQUIRES => {
        'Test::Simple' => 1.001, # for Test::More
        'Test::Pod' => 1.48,
        'Test::Exception' => 0.38,
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    clean => {
        FILES => 'HTTP-OAIPMH-Validator-*'
    },
);

# Add in cover and coverclean targets
#
# Do this by simply writing text verbatim into the postamble
# section of the Makefile. Based on
# <http://search.cpan.org/~bingos/ExtUtils-MakeMaker-7.04/lib/ExtUtils/MakeMaker.pm#Overriding_MakeMaker_Methods>
#
# FIXME - should find a way to add coverclean to clean
#
sub MY::postamble {
    return << "COVER";
\ncover:
\tPERL5OPT=-MDevel::Cover=-coverage,statement,branch,condition,path,subroutine,-ignore,prove,t/ prove -lr t
\tcover
\ncoverclean:
\trm -rf cover_db\n
COVER
}

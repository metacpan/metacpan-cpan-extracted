use strict;
use warnings;
use ExtUtils::MakeMaker;


warn <<EOT;





############################___ NOTICE ___##############################
#                                                                      #
#  Some of the tests require some information from you.  The scripts   #
#  script/flickr_make_stored_config.pl and                             #
#  script/flickr_make_test_values.pl                                   #
#  from the Flickr::API distribution can help you gather this          #
#  this information. Executing either script with the --help flag will #
#  explain the arguments you need for these scripts.                   #
#                                                                      #
#  The authentication tests use either the MAKETEST_OAUTH_CFG or the   #
#  MAKETEST_FLICKR_CFG environment variables or both. The result tests #
#  use the MAKETEST_VALUES environment variable. You can use any of    #
#  environment variables with the others.                              #
#                                                                      #
# If you want to run these tests, answer `No' to the question below    #
# and run the script or build your own config by hand. When you are    #
# ready for "make test" use:                                           #
#    make test MAKETEST_OAUTH_CFG=/the/path/to/above/filename          #
# or                                                                   #
#    make test MAKETEST_FLICKR_CFG=/the/path/to/above/filename         #
# or                                                                   #
#    make test MAKETEST_VALUES=/the/path/to/above/filename             #
# or any combination of the above.                                     #
#                                                                      #
############################___ NOTICE ___##############################

EOT
my $ans = prompt('Do you want to continue?', 'yes');
exit 0 unless $ans =~ /^y(es)?\z/i;



WriteMakefile(
    NAME                => 'Flickr::Tools',
    AUTHOR              => 'Louis B. Moore <lbmoore@cpan.org>',
    VERSION_FROM        => 'lib/Flickr/Tools.pm',
    ABSTRACT_FROM       => 'lib/Flickr/Tools.pm',
    'LICENSE'           => 'artistic2',
    'MIN_PERL_VERSION'  => '5.010',
    PL_FILES            => {},
    'META_MERGE'        => {
        resources => {
            repository  =>  'https://github.com/lbmoore/perl-Flickr-Tools',
        },
    },
    PREREQ_PM => {
        'Carp' => 0,
        'Cache' => 0,
        'CHI' => 0,
        'Flickr::API' => '1.26',
        'Flickr::API::Cameras' => '1.26',
        'Flickr::API::Reflection' => '1.26',
        'Moo' => 0,
        'Moo::Role' => 0,
        'Test::More' => 0,
        'Test::TypeTiny' => 0,
        'Type::Library' => 0,
        'Type::Params' => 0,
        'Type::Utils' => 0,
        'Types::Standard' => 0,
        'namespace::clean' => 0,
        'strictures' => 0,
    },
    'TEST_REQUIRES'  =>  {
        'Test::TypeTiny' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Flickr-Tools-*' },
);

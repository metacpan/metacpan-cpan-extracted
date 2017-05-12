use ExtUtils::MakeMaker;

warn <<EOT;





############################___ NOTICE ___##############################
#                                                                      #
#  Some of the api authentication and results tests require some       #
#  information from you. Scripts script/flickr_make_stored_config.pl   #
#  and script/flickr_make_test_values.pl are an easy way to assemble   #
#  this information. Executing either script with the --help flag will #
#  explain the arguments you need for these scripts.                   #
#                                                                      #
#  The authentication tests use either the MAKETEST_OAUTH_CFG or the   #
#  MAKETEST_FLICKR_CFG environment variables or both. The result tests #
#  use the MAKETEST_VALUES environment variable. You can use any of    #
#  environment variables with the others.                              #
#                                                                      #
#  Tests that interact with Flickr will also need the                  #
#  MAKETEST_OAUTH_CFG or the MAKETEST_FLICKR_CFG environment variables #
#  or both. If you want to interact with Flickr, but don't want to     #
#  go through the authentication process, again, then you can specify  #
#  MAKETEST_OAUTH_AUTHED=1 and/or MAKETEST_FLICKR_AUTHED=1 as needed   #
#  to bypass the authentication tests.                                 #
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
    'NAME'		=> 'Flickr::API',
    'VERSION_FROM'	=> 'lib/Flickr/API.pm',
    'LICENSE'           => 'perl',
    'MIN_PERL_VERSION'  => '5.008',
    'META_MERGE'        => {
        resources => {
            repository  =>  'https://github.com/iamcal/perl-Flickr-API',
        },
    },
    'PREREQ_PM'        => {
        'LWP::UserAgent' => 0,
        'HTTP::Request' => 0,
        'HTTP::Request::Common' => 0,
        'HTTP::Response' => 0,
        'HTTP::Message' => 1.56, # first version of libwww that supports decoded_content()
        'URI' => 1.18,
        'XML::Parser::Lite::Tree' => 0.06,
        'XML::LibXML::Simple' => 0,
        'Digest::MD5' => 0,
        'Getopt::Long' => 1,
        'parent' => 0,
        'Test::More' => 0,
        'Test::Script' => 0,
        'Net::OAuth' => 0,
    },
    'TEST_REQUIRES'  =>  {
        'Test::Script' => 0,
    },
    'EXE_FILES' =>
        [
            'script/flickr_dump_stored_config.pl',
            'script/flickr_make_stored_config.pl',
            'script/flickr_make_test_values.pl',
        ]
    );

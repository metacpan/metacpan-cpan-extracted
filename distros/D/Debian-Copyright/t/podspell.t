use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Spelling; };

if ( $@) {
   my $msg = 'Test::Spelling required to criticise code';
   plan( skip_all => $msg );
}

Test::Spelling::add_stopwords(qw(   Ivanov
                                    Damyan
                                    CPAN
                                    Bamber
                                    github
                                    AnnoCPAN
                                    RT
                                    API
                                    crypted
                                    HTML
                                    TODO
                                    URL
                                    dh
                                    Plessy
                                    CAPAUTHTOKEN
                                    Hardcode
                                    hardcode
                                    everytime
                                    initialize
                                    authen
                                    customizations
                                    runmode
                                    runmodes
                                    prerun
                                    pre
                                    callback
                                    DEP
                                    checkbox
                                    customize
                                    customized
                                    desaturating
                                    detaint
                                    URLs));
Test::Spelling::all_pod_files_spelling_ok();


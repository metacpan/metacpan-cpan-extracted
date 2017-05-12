use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Spelling; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Spelling required to criticise code';
   plan( skip_all => $msg );
}

Test::Spelling::add_stopwords(qw(   AnnoCPAN
                                    API
                                    Bamber
                                    CPAN
                                    Unported
                                    wikipedia
                                    detaint
                                    ShareAlike
                                    github
                                    HTML
                                    URL
                                    inline
                                    javascript
                                    RT
                                    XHTML
                                    utf8
                                    XS
                                    XSS));
Test::Spelling::all_pod_files_spelling_ok();


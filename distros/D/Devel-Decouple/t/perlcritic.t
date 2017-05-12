use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_CRITIC} ) {
    my $msg = 'Author test.  Set $ENV{TEST_CRITIC} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $@ ) {
    my $msg = 'Test::Perl::Critic required to criticize code.';
    plan( skip_all => $msg );
}

Test::Perl::Critic->import(
                            -severity   => 5                            ,       # be gentle
                            -verbose    => '[%p %e]: %m at %f line %l\n',       # with descriptive msgs...
                            -exclude    =>  [
                                                'RequirePodSections'    ,
                                            ]                           ,
                          );

Test::Perl::Critic::all_critic_ok();

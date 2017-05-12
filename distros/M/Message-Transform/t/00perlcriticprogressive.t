use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic::Progressive; };

if ($EVAL_ERROR) {
    my $msg =
'Test::Perl::Critic::Progressive required to progressively criticise code';
    plan( skip_all => $msg );
}

Test::Perl::Critic::Progressive::progressive_critic_ok();
unlink 't/.perlcritic-history';

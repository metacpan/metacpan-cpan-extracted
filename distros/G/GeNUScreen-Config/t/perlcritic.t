#!perl
# vim: sw=4 ts=4 tw=78 et si:

use Test::More;
eval "use Test::Perl::Critic";
plan skip_all => "Test::Perl::Critic required for testing PBP compliance" if $@;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

Test::Perl::Critic::all_critic_ok();

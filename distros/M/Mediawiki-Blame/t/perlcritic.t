#!perl -T
use strict;
use warnings;
use File::HomeDir qw();
use File::Spec::Functions qw(catfile);
use Test::More;

if (not $ENV{TEST_AUTHOR}) {
    plan skip_all => '-- Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
};

eval q{
    use Test::Perl::Critic (
        '-severity' => 3,
        '-verbose' => 8,
        '-profile' => catfile(File::HomeDir->my_home, '.perlcriticrc')
    );
};

if ($@) {
    plan skip_all => 'Test::Perl::Critic required to criticise code';
};

all_critic_ok();

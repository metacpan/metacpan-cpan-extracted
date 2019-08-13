#!perl

use strict;
use warnings FATAL => 'all';
use Test::More;

unless ( $ENV{AUTHOR_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval q~use Test::Perl::Critic~;
plan skip_all => "Test::Perl::Critic  required" if $@;

Test::Perl::Critic->import(
    -severity => 'brutal',
    -exclude  => [
        'ProhibitStringyEval',
        'ProhibitHashBarewords',
        'ProhibitPostfixControls',
        'RequireTidyCode',
        'ProhibitBuiltinHomonyms',
        'RequireArgUnpacking',
        'ProhibitPunctuationVars',

        # file yml
        'RequireCheckedSyscalls',
        'RequireCheckedClose',

        # sqlite converter
        'ProhibitMultiplePackages',

        #weired regex stuff
        'ProhibitEscapedMetacharacters',
        'RequireExtendedFormatting',
        'RequireDotMatchAnything',
        'RequireLineBoundaryMatching',

        # I'm using unless, deal with it
        'ProhibitUnlessBlocks',

        # Some sub are called from string
        'ProhibitUnusedPrivateSubroutines',

        'ProhibitLongChainsOfMethodCalls'
    ]
);

all_critic_ok();

#!perl
### no critic [ValuesAndExpressions::ProhibitConstantPragma]
### no critic (Subroutines::ProtectPrivateSubs)
use strict;
use warnings;
use Test2::V0;

use Env::Dot::Functions ();

subtest 'Private Subroutine interpret_dotenv_filepath_var()' => sub {

    {
        my $var   = q{};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [], 'Filepaths right' );
    }

    {
        my $var   = q{.};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [q{.}], 'Filepaths right' );
    }

    {
        my $var   = q{/home/user/.env};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [ q{/home/user/.env}, ], 'Filepaths right' );
    }

    {
        my $var   = q{/home/user/.env:subdir/.env};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [ q{/home/user/.env}, q{subdir/.env}, ], 'Filepaths right' );
    }

    {
        my $var   = q{/home/:subdir/.env:/};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [ q{/home/}, q{subdir/.env}, q{/}, ], 'Filepaths right' );
    }

    {
        my $var   = q{/home};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        isnt( \@paths, [ q{/home/me}, ], 'Filepaths right' );
    }

    done_testing;
};

done_testing;

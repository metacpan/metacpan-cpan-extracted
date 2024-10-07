#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;
use Test2::V0;

use FindBin    qw( $RealBin );
use File::Spec ();
my $lib_path;

BEGIN {
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], q{.}, 'lib' );
}
use lib "$lib_path";

use Test2::Require::Platform::Unix;

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
        my $var   = q{:};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [], 'Filepaths right' );
    }

    {
        my $var   = q{;};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [q{;}], 'Filepaths right' );
    }

    {
        my $var   = q{/home/user/.env};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [ q{/home/user/.env}, ], 'Filepaths right' );
    }

    {
        my $var   = q{/home/user/.env:};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [ q{/home/user/.env}, ], 'Filepaths right' );
    }

    {
        my $var   = q{:/home/user/.env};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [ q{}, q{/home/user/.env}, ], 'Filepaths right' );
    }

    {
        my $var   = q{:/home/user/.env:};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [ q{}, q{/home/user/.env}, ], 'Filepaths right' );
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
        my $var   = q{C:\Users\me};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [ q{C}, q{\Users\me}, ], 'Filepaths correct, Win paths' );
    }

    {
        my $var   = q{/home/me/.env;/home/you/.env:/home/you/subdir/.env};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is( \@paths, [ q{/home/me/.env;/home/you/.env}, q{/home/you/subdir/.env}, ], 'Filepaths correct, not Windows paths' );
    }

    {
        my $var   = q{C:\Users\.env;C:\home\you\.env:C:\home\you\subdir\.env};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        is(
            \@paths,
            [ q{C}, q{\Users\.env;C}, q{\home\you\.env}, q{C}, q{\home\you\subdir\.env}, ],
            'Filepaths correct, not Windows paths'
        );
    }

    {
        my $var   = q{/home};
        my @paths = Env::Dot::Functions::interpret_dotenv_filepath_var($var);
        isnt( \@paths, [ q{/home/me}, ], 'Filepaths correctly not right' );
    }

    done_testing;
};

done_testing;

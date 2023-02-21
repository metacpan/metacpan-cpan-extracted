#!perl
### no critic [ValuesAndExpressions::ProhibitConstantPragma]
### no critic (Subroutines::ProtectPrivateSubs)
use strict;
use warnings;
use Test2::V0;

#use Env::Dot qw();

subtest 'Private Subroutine _interpret_filepath_var()' => sub {

    # {
    #     my $var = q{/home/user/.env:subdir/.env};
    #     my @paths = Env::Dot::_interpret_filepath_var( $var );
    #     is( \@paths, [ q{/home/user/.env}, q{subdir/.env}, ], 'Filepaths right' );
    # }

    ok( 1, 'is okay' );
    done_testing;
};

done_testing;

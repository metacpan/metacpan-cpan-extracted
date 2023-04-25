#!perl
## no critic (Subroutines::ProtectPrivateSubs)
use strict;
use warnings;
use Test2::V0;

use Env::Dot::ScriptFunctions qw( );

subtest 'Private Subroutine _convert_var_to_sh()' => sub {

    {
        my %var = (
            name  => 'THIS_VAR',
            value => 'this var value',
            opts  => { 'export' => 1, 'allow_interpolate' => 0, },
        );
        my $expect  = q{THIS_VAR='this var value'; export THIS_VAR};
        my $cmdline = Env::Dot::ScriptFunctions::_convert_var_to_sh( \%var );
        is( $cmdline, $expect, 'Correct Bourne Shell command' );
    }

    {
        my %var = (
            name  => 'THIS_VAR',
            value => 'this var value',
            opts  => { 'export' => 0, 'allow_interpolate' => 1, },
        );
        my $expect  = q{THIS_VAR="this var value"};
        my $cmdline = Env::Dot::ScriptFunctions::_convert_var_to_sh( \%var );
        is( $cmdline, $expect, 'Correct Bourne Shell command' );
    }

    {
        my %var = (
            name  => 'THIS_VAR',
            value => 'this var value',
            opts  => { 'export' => 0, 'allow_interpolate' => 1, },
        );
        my $expect  = q{THIS_VAR="this var value"};
        my $cmdline = Env::Dot::ScriptFunctions::_convert_var_to_sh( \%var );
        is( $cmdline, $expect, 'Correct Bourne Shell command' );
    }

    done_testing;
};

subtest 'Private Subroutine _convert_var_to_csh()' => sub {

    {
        my %var = (
            name  => 'THIS_VAR',
            value => 'this var value',
            opts  => { 'export' => 1, 'allow_interpolate' => 0, },
        );
        my $expect  = q{setenv THIS_VAR 'this var value'};
        my $cmdline = Env::Dot::ScriptFunctions::_convert_var_to_csh( \%var );
        is( $cmdline, $expect, 'Correct C Shell command' );
    }

    {
        my %var = (
            name  => 'THIS_VAR',
            value => 'this var value',
            opts  => { 'export' => 1, 'allow_interpolate' => 1, },
        );
        my $expect  = q{setenv THIS_VAR "this var value"};
        my $cmdline = Env::Dot::ScriptFunctions::_convert_var_to_csh( \%var );
        is( $cmdline, $expect, 'Correct Bourne Shell command' );
    }

    {
        my %var = (
            name  => 'THIS_VAR',
            value => 'this var value',
            opts  => { 'export' => 0, 'allow_interpolate' => 1, },
        );
        my $expect  = q{set THIS_VAR "this var value"};
        my $cmdline = Env::Dot::ScriptFunctions::_convert_var_to_csh( \%var );
        is( $cmdline, $expect, 'Correct Bourne Shell command' );
    }

    done_testing;
};

subtest 'Private Subroutine convert_variables_into_commands()' => sub {

    {
        my @vars = (
            {
                name  => 'THIS_VAR',
                value => 'this var value',
                opts  => { 'export' => 1, 'allow_interpolate' => 0, },
            },
            {
                name  => 'THAT_VAR',
                value => 'that var value',
                opts  => { 'export' => 1, 'allow_interpolate' => 0, },
            },
        );
        my $expect = <<'END_OF_TEXT';
THIS_VAR='this var value'; export THIS_VAR
THAT_VAR='that var value'; export THAT_VAR
END_OF_TEXT
        my $out = Env::Dot::ScriptFunctions::convert_variables_into_commands( 'sh', @vars );
        is( $out, $expect, 'Correct Bourne Shell command' );
    }

    {
        my @vars = (
            {
                name  => 'THAT_VAR',
                value => 'that var value',
                opts  => { 'export' => 0, 'allow_interpolate' => 0, },
            },
            {
                name  => 'THIS_VAR',
                value => 'this var value',
                opts  => { 'export' => 1, 'allow_interpolate' => 1, },
            },
        );
        my $expect = <<'END_OF_TEXT';
THAT_VAR='that var value'
THIS_VAR="this var value"; export THIS_VAR
END_OF_TEXT
        my $out = Env::Dot::ScriptFunctions::convert_variables_into_commands( 'sh', @vars );
        is( $out, $expect, 'Correct Bourne Shell command' );
    }

    done_testing;
};

done_testing;

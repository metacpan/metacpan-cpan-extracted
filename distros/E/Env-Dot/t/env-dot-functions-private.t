#!perl
## no critic (Subroutines::ProtectPrivateSubs)
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strict;
use warnings;
use Test2::V0;

use Env::Dot::Functions qw( );

subtest 'Private Subroutine _interpret_opts()' => sub {

    {
        my $opts_str = 'exact=1';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 1, );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=0';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 0, );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=123';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 123, );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=1.234';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 1.234, );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=1,234';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = (
            exact => 1,
            234   => 1,    # Option without a value is interpreted as boolean with true value.
        );
        is( $opts, \%expected, 'Read options successfully, but options not valid' );
    }

    {
        my $opts_str = 'key_1=1,key_2=234, key_3=text , key_4=more text, key_5=';
        my $opts     = Env::Dot::Functions::_interpret_opts($opts_str);
        my %expected = (
            key_1 => 1,
            key_2 => 234,
            key_3 => 'text',
            key_4 => 'more text',
            key_5 => q{},
        );
        is( $opts, \%expected, 'Read options successfully' );
    }

    done_testing;
};

subtest 'Private Subroutine _interpret_dotenv()' => sub {

    {
        my $dotenv = <<'END_OF_TEXT';
# Here's some envs
# envdot (file:type=shell)

FIRST_VAR='My first var'
THIRD_VAR="My third var"
# envdot (file:type=plain)
# The quotation marks become part of the variable value.
SECOND_VAR='My second var'
FIFTH_VAR=123
SIXTH_VAR=123.456
END_OF_TEXT
        my @vars     = Env::Dot::Functions::_interpret_dotenv( split qr{\n}msx, $dotenv );
        my %def_opts = ( allow_interpolate => 0, );
        is(
            \@vars,
            [
                { name => q{FIRST_VAR},  value => q{My first var},    opts => \%def_opts, },
                { name => q{THIRD_VAR},  value => q{My third var},    opts => \%def_opts, },
                { name => q{SECOND_VAR}, value => q{'My second var'}, opts => \%def_opts, },
                { name => q{FIFTH_VAR},  value => q{123},             opts => \%def_opts, },
                { name => q{SIXTH_VAR},  value => q{123.456},         opts => \%def_opts, },
            ],
            'dotenv file correctly interpreted'
        );
    }

    {
        my $dotenv = <<'END_OF_TEXT';
# Here's some envs
# envdot (file:type=plain)
THIRD_VAR=My third var
SECOND_VAR=My second var!@#$ %  # no comment allowed here

# envdot (file:type=shell)
FIRST_VAR='My first var'; export FIRST_VAR
FOURTH_VAR='My fourth var'
FIFTH_VAR=123
SIXTH_VAR=123.456
export SEVENTH_VAR=7654321

END_OF_TEXT
        my @vars     = Env::Dot::Functions::_interpret_dotenv( split qr{\n}msx, $dotenv );
        my %def_opts = ( allow_interpolate => 0, );
        ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
        is(
            \@vars,
            [
                { name => q{THIRD_VAR},   value => q{My third var},                                   opts => \%def_opts, },
                { name => q{SECOND_VAR},  value => q{My second var!@#$ %  # no comment allowed here}, opts => \%def_opts, },
                { name => q{FIRST_VAR},   value => q{My first var},                                   opts => \%def_opts, },
                { name => q{FOURTH_VAR},  value => q{My fourth var},                                  opts => \%def_opts, },
                { name => q{FIFTH_VAR},   value => q{123},                                            opts => \%def_opts, },
                { name => q{SIXTH_VAR},   value => q{123.456},                                        opts => \%def_opts, },
                { name => q{SEVENTH_VAR}, value => q{7654321},                                        opts => \%def_opts, },
            ],
            'dotenv file correctly interpreted'
        );
    }

    {
        my $dotenv = <<'END_OF_TEXT';
FIFTH_VAR=123
SIXTH_VAR=123.456
END_OF_TEXT
        my @vars     = Env::Dot::Functions::_interpret_dotenv( split qr{\n}msx, $dotenv );
        my %def_opts = ( allow_interpolate => 0, );
        is(
            \@vars,
            [
                { name => q{FIFTH_VAR}, value => q{123},     opts => \%def_opts, },
                { name => q{SIXTH_VAR}, value => q{123.456}, opts => \%def_opts, },
            ],
            'dotenv file correctly interpreted'
        );
    }
    done_testing;
};

done_testing;

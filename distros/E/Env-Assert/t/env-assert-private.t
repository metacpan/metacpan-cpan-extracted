#!perl
## no critic (Subroutines::ProtectPrivateSubs)
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strict;
use warnings;
use Test2::V0;

use Env::Assert::Functions qw( );

subtest 'Private Subroutine _interpret_opts()' => sub {

    {
        my $opts_str = 'exact=1';
        my $opts = Env::Assert::Functions::_interpret_opts( $opts_str );
        my %expected = (
            exact => 1,
        );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=0';
        my $opts = Env::Assert::Functions::_interpret_opts( $opts_str );
        my %expected = (
          exact => 0,
        );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=123';
        my $opts = Env::Assert::Functions::_interpret_opts( $opts_str );
        my %expected = (
          exact => 123,
        );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=1.234';
        my $opts = Env::Assert::Functions::_interpret_opts( $opts_str );
        my %expected = (
          exact => 1.234,
        );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=1,234';
        my $opts = Env::Assert::Functions::_interpret_opts( $opts_str );
        my %expected = (
          exact => 1,
          234 => undef
        );
        is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'key_1=1,key_2=234, key_3=text , key_4=more text, key_5=';
        my $opts = Env::Assert::Functions::_interpret_opts( $opts_str );
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

done_testing;

#!perl
## no critic (Subroutines::ProtectPrivateSubs)
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strict;
use warnings;
use Test2::V1 qw( -utf8 -x -strict -warnings ), -include => ['Data::Dumper'];
use Test2::Tools::Subtest qw( subtest_streamed );

use Env::Assert::Functions qw( );

subtest_streamed 'Private Subroutine _interpret_opts()' => sub {

    {
        my $opts_str = q{};
        my $opts     = Env::Assert::Functions::_interpret_opts($opts_str);
        my %expected;
        T2->is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact';
        my $opts     = Env::Assert::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 1, );
        T2->is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=1';
        my $opts     = Env::Assert::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 1, );
        T2->is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=0';
        my $opts     = Env::Assert::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 0, );
        T2->is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=123';
        my $opts     = Env::Assert::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 123, );
        T2->is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=1.234';
        my $opts     = Env::Assert::Functions::_interpret_opts($opts_str);
        my %expected = ( exact => 1.234, );
        T2->is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=1,234';
        my $opts     = Env::Assert::Functions::_interpret_opts($opts_str);
        my %expected = (
            exact => 1,
            234   => 1,
        );
        T2->is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact=1, some_true, other_true, other_false = 0';
        my $opts     = Env::Assert::Functions::_interpret_opts($opts_str);
        my %expected = (
            exact       => 1,
            some_true   => 1,
            other_true  => 1,
            other_false => 0,
        );
        T2->is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'exact = 0, words_and_space = one two three_go';
        my $opts     = Env::Assert::Functions::_interpret_opts($opts_str);
        my %expected = (
            exact           => 0,
            words_and_space => q{one two three_go},
        );
        T2->is( $opts, \%expected, 'Read options successfully' );
    }

    {
        my $opts_str = 'key_1=1,key_2=234, key_3 =text , key_4= more text, key_5= ';
        my $opts     = Env::Assert::Functions::_interpret_opts($opts_str);
        my %expected = (
            key_1 => 1,
            key_2 => 234,
            key_3 => 'text',
            key_4 => 'more text',
            key_5 => q{},
        );
        T2->is( $opts, \%expected, 'Read options successfully' );
    }

    T2->done_testing;
};

T2->done_testing;

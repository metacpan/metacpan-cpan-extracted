#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;

{
    package An::Exporter;
    use Exporter::Declare;

    default_exports qw/ a /;
    exports qw/ b c $X /;

    our $X = 'x';

    sub a { 'a' }
    sub b { 'b' }
    sub c { 'c' }
}
{
    package Old::Exporter;
    use base 'Exporter';

    our @EXPORT = qw/ d e f $Y /;

    our $Y = 'y';

    sub d { 'd' }
    sub e { 'e' }
    sub f { 'f' }
}
{
    package Combination;
    use Exporter::Declare qw/reexport import/;

    reexport 'An::Exporter';
    reexport 'Old::Exporter';
}

tests meta_data => sub {
    is_deeply(
        [ sort keys %{ Combination->export_meta->exports }],
        [ sort qw/ &a &b &c &d &e &f $Y $X &Combination/],
        "All exports"
    );
    is_deeply(
        [ sort @{ Combination->export_meta->export_tags->{ all }}],
        [ sort qw/ &a &b &c &d &e &f $Y $X &Combination/],
        "All exports tag"
    );
    is_deeply(
        [ sort @{ Combination->export_meta->export_tags->{ default }}],
        [ sort qw/ a d e f $Y / ],
        "Defaults"
    );
};

tests imports => sub {
    Combination->import('-all');
    can_ok( __PACKAGE__, qw/a b c d e f/ );
    is( a(), 'a', "a()" );
    is( b(), 'b', "b()" );
    is( c(), 'c', "c()" );
    is( d(), 'd', "d()" );
    is( e(), 'e', "e()" );
    is( f(), 'f', "f()" );
    no strict 'vars';
    no warnings 'once';
    is( $X, 'x', '$X' );
    is( $Y, 'y', '$Y' );
};

run_tests;
done_testing;

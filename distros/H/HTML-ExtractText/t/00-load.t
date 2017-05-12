#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan tests => 7;

BEGIN {
    use_ok('Try::Tiny');
    use_ok('Scalar::Util');
    use_ok('Carp');
    use_ok('Devel::TakeHashArgs');
    use_ok('Mojo::DOM');
    use_ok('overload');
    use_ok('HTML::ExtractText') || print "Bail out!\n";
}
diag( 'Testing HTML::ExtractText'
    . " $HTML::ExtractText::VERSION, Perl $], $^X" );
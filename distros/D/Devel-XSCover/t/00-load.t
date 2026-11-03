#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

my @modules = qw(
    Devel::XSCover
    Devel::XSCover::Build
    Devel::XSCover::Test
    Devel::XSCover::Deparse
    Devel::XSCover::Gcov
    Devel::XSCover::XS
    Devel::XSCover::DB
    Devel::Cover::Report::XSCover
);

plan tests => scalar @modules;

for my $module (@modules) {
    use_ok($module) || print "Bail out! Cannot load $module\n";
}

diag( "Testing Devel::XSCover $Devel::XSCover::VERSION, Perl $], $^X" );

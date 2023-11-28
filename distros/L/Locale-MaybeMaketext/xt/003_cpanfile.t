#!perl
use strict;
use warnings;
use vars;
use Test2::V0 qw/ok pass fail diag note skip plan done_testing todo/;
use Test2::Plugin::BailOnFail;
use Test2::Plugin::ExitSummary;
use Test2::Formatter::TAP;
use Test2::Require::Module 'Test::CPANfile';
use Test::CPANfile;
use Carp qw/carp croak/;

use feature qw/signatures/;
no if $] >= 5.032, q|feature|, qw/indirect/;
no warnings qw/experimental::signatures/;

cpanfile_has_all_used_modules(
    'recommends' => 1,
    'suggests'   => 1,
);
done_testing;

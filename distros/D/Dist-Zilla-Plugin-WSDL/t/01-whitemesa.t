#!/usr/bin/env perl

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use utf8;
use Cwd;
use Dist::Zilla::Tester 4.101550;
use File::Temp;
use Test::Most 'bail';
use Test::RequiresInternet ( 'www.whitemesa.com' => 80 );
use Test::Moose;

use Dist::Zilla::Plugin::WSDL;

plan tests => 1;

my $dist_dir = File::Temp->newdir();
my $zilla    = Dist::Zilla::Tester->from_config(
    { dist_root => "$dist_dir" },
    { add_files => { 'source/dist.ini' => <<'END_INI'} },
name     = test
author   = test user
abstract = test release
license  = Perl_5
version  = 1.0
copyright_holder = test holder

[WSDL]
uri = http://www.whitemesa.com/r3/InteropTestDocLitParameters.wsdl
prefix = Local::Test::My
END_INI
);
lives_ok( sub { $zilla->build() } );

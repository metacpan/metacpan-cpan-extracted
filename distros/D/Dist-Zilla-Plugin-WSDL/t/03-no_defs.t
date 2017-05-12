#!/usr/bin/env perl

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use utf8;
use Cwd;
use Dist::Zilla::Tester 4.101550;
use File::Temp;
use Test::Most 'bail', tests => 1;
use Test::Moose;

use Dist::Zilla::Plugin::WSDL;

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
uri = http://example.com/path/to/service.wsdl
prefix = Local::Test::My
END_INI
);
throws_ok(
    sub { $zilla->build() },
    qr/\A [[] WSDL []] \s /msx,
    'WSDL exception',
);

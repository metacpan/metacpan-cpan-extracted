#!/usr/bin/env perl

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use utf8;
use Const::Fast;
use Cwd;
use English '-no_match_vars';
use Dist::Zilla::Tester 4.101550;
use File::Temp;
use Path::Class;
use Test::Most;
use Test::RequiresInternet ( 'www.whitemesa.com' => 80 );
use Test::Moose;

use Dist::Zilla::Plugin::WSDL;

my $tests;
const my $PREFIX        => 'Local::Test::My';
const my $DIST_DIR      => File::Temp->newdir();
const my $TYPEMAP_CLASS => "${PREFIX}Typemaps::WSDLInteropTestDocLitService";
const my %TYPEMAP       => (
    TestTypeString => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    TestTypeToken  => 'SOAP::WSDL::XSD::Typelib::Builtin::token',
);
const my $TYPEMAP_CONF => join q{},
    map {"typemap = $_ => $TYPEMAP{$_}\n"} keys %TYPEMAP;
plan tests => scalar keys %TYPEMAP;

my $zilla = Dist::Zilla::Tester->from_config(
    { dist_root => "$DIST_DIR" },
    { add_files => { 'source/dist.ini' => <<"END_INI"} },
name     = test
author   = test user
abstract = test release
license  = Perl_5
version  = 1.0
copyright_holder = test holder

[WSDL]
uri = http://www.whitemesa.com/r3/InteropTestDocLitParameters.wsdl
prefix = $PREFIX
$TYPEMAP_CONF
END_INI
);

$zilla->build();
push @INC => dir( $zilla->tempdir, qw(source lib) )->stringify;
eval "require $TYPEMAP_CLASS";
while ( my ( $key, $class ) = each %TYPEMAP ) {
    is( $TYPEMAP_CLASS->get_class( [$key] ), $class, "typemap $key" );
}

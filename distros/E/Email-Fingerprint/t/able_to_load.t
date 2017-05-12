#!/usr/bin/perl

use Test::More tests => 4;

BEGIN {
    use_ok( 'Email::Fingerprint' );
    use_ok( 'Email::Fingerprint::App::EliminateDups' );
    use_ok( 'Email::Fingerprint::Cache' );
    use_ok( 'Email::Fingerprint::Cache::AnyDBM' );
}

diag( "Testing Email::Fingerprint $Email::Fingerprint::VERSION, Perl $]" );

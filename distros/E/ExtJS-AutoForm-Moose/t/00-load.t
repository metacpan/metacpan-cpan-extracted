#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'ExtJS::AutoForm::Moose' ) || print "Bail out!
";
    use_ok( 'ExtJS::AutoForm::Moose::Types' ) || print "Bail out!
";
    use_ok( 'ExtJS::AutoForm::Moose::Util' ) || print "Bail out!
";
}

diag( "Testing ExtJS::Reflection $ExtJS::AutoForm::Moose::VERSION, Perl $], $^X" );

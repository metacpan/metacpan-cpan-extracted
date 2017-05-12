#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'HTML::Widgets::NavMenu::ToJSON' ) || print "Bail out!\n";
    use_ok( 'HTML::Widgets::NavMenu::ToJSON::Data_Persistence' ) || print "Bail out!\n";
    use_ok( 'HTML::Widgets::NavMenu::ToJSON::Data_Persistence::YAML' ) || print "Bail out!\n";
}

diag( "Testing HTML::Widgets::NavMenu::ToJSON $HTML::Widgets::NavMenu::ToJSON::VERSION, Perl $], $^X" );

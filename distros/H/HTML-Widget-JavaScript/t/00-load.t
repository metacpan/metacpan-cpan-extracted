#!perl -w

use Test::More tests => 15;

BEGIN {
	use_ok( 'HTML::Widget::JavaScript' );
	use_ok( 'HTML::Widget::JavaScript::Result' );
	use_ok( 'HTML::Widget::JavaScript::Constraint::All' );
	use_ok( 'HTML::Widget::JavaScript::Constraint::AllOrNone' );
	use_ok( 'HTML::Widget::JavaScript::Constraint::Any' );
	use_ok( 'HTML::Widget::JavaScript::Constraint::ASCII' );
	SKIP: {
           eval "require Email::Valid";
           skip "Email::Valid not installed", 1 if $@;
           use_ok( 'HTML::Widget::JavaScript::Constraint::Email' );
        }
	use_ok( 'HTML::Widget::JavaScript::Constraint::Equal' );
	use_ok( 'HTML::Widget::JavaScript::Constraint::HTTP' );
	use_ok( 'HTML::Widget::JavaScript::Constraint::In' );
	use_ok( 'HTML::Widget::JavaScript::Constraint::Integer' );
	use_ok( 'HTML::Widget::JavaScript::Constraint::Length' );
	use_ok( 'HTML::Widget::JavaScript::Constraint::Printable' );
	use_ok( 'HTML::Widget::JavaScript::Constraint::Range' );
	use_ok( 'HTML::Widget::JavaScript::Constraint::String' );
}

diag( "Testing HTML::Widget::JavaScript $HTML::Widget::JavaScript::VERSION, Perl $], $^X" );

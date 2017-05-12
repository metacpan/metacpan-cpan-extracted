use Test::More tests => 2;

BEGIN {
use_ok( 'HTML::WidgetValidator' );
}
ok( HTML::WidgetValidator->new );
diag( "Testing HTML::WidgetValidator $HTML::WidgetValidator::VERSION" );

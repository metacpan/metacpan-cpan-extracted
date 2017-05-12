use Test; 
BEGIN { plan tests => 6 }
use JavaScript::DebugConsole;

ok(1);

# create new object
ok( my $jdc = new JavaScript::DebugConsole() );

ok( $jdc->add('This', 'is' , 'my', 'text') );
ok( $jdc->debugConsole( title => 'Debug Text 1', debug => 0 ) );
ok( $jdc->link );
ok( $jdc->debugConsole( content => "Another text", title => 'Debug Text 2', 
	form => { param1 => 'value1', param2 => 'value2' } , auto_open => 0 ) );
print $jdc->{'console'};
print $jdc->link;

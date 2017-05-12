use Test::More 0.95;

my $class = 'HTML::SimpleLinkExtor';
use_ok( $class ); 

my $html = '<html><body><form name="test"
action="/test"><input type="submit" /></form></body></html>'; 

my $extor = $class->new(); 
isa_ok( $extor, $class );

$extor->parse( $html ); 

print STDERR join "\n", $extor->links;

done_testing();

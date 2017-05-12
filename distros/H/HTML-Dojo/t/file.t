use Test::More tests => 6;

use_ok 'HTML::Dojo';

ok( my $dojo = HTML::Dojo->new );

{
    my $file = $dojo->file( 'dojo.js' );
    
    ok( $file =~ /Copyright/ );    
}

{
    my $file = $dojo->file( 'dojo.js', {edition => 'kitchen_sink'} );
    
    ok( $file =~ /Copyright/ );
}

{
    my $file = $dojo->file( 'src/bootstrap1.js' );
    
    ok( $file =~ /dojo\.global = function/ );
    ok( $file =~ /dojo\.version = / );
}


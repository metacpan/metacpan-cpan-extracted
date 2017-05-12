use Test::More tests => 11;

use_ok 'HTML::Dojo';

ok( my $dojo = HTML::Dojo->new );

{
    my $list = $dojo->list;
    
    ok( grep { $_ eq 'dojo.js' } @$list );
    
    ok( grep { $_ eq 'src/bootstrap1.js' } @$list );
    
    ok( ! grep { $_ eq 'src' } @$list );
}

{
    my $list = $dojo->list( { directories => 1 } );
    
    ok( grep { $_ eq 'dojo.js' } @$list );
    
    ok( grep { $_ eq 'src/bootstrap1.js' } @$list );
    
    ok( grep { $_ eq 'src' } @$list );
}

{
    my $list = $dojo->list( { files => 0 } );
    
    ok( ! grep { $_ eq 'dojo.js' } @$list );
    
    ok( ! grep { $_ eq 'src/bootstrap1.js' } @$list );
    
    ok( ! grep { $_ eq 'src' } @$list );
}


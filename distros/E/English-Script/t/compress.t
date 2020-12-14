use strict;
use warnings;
use Test::Most;

use_ok('English::Script');

my $es;
lives_ok( sub { $es = English::Script->new(
    renderer    => 'JavaScript',
    render_args => { compress => 'clean' },
) }, 'new' );
lives_ok( sub { $es->parse('Set answer to 42.') }, 'set object to value' );
is( $es->render, 'if(typeof(answer)=="undefined")var answer="";answer=42;', 'JavaScript clean compression' );

done_testing;

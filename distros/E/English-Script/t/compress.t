use Test2::V0;
use English::Script;

my $es;
ok( lives { $es = English::Script->new(
    renderer    => 'JavaScript',
    render_args => { compress => 'clean' },
) }, 'new' ) or note $@;
ok( lives { $es->parse('Set answer to 42.') }, 'set object to value' ) or note $@;
is( $es->render, 'if(typeof(answer)=="undefined")var answer="";answer=42;', 'JavaScript clean compression' );

done_testing;

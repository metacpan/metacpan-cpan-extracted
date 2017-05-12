use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $v= Egg::Helper::VirtualTest->new;
   $v->prepare(
     controller=> { egg_includes=> [qw/JSON/] },
     config=> { VIEW=> [ [ JSON => {} ] ] },
     );

ok my $e= $v->egg_pcomp_context;
ok my $view= $e->view('JSON');
isa_ok $view, 'Egg::View::JSON';
can_ok $view, qw/obj x_json render output/;
ok my $obj= $view->obj({ test1=> 1, test2=> 2 });
ok my $json_code= $view->render($obj);
ok my $json_obj = $e->json2obj($json_code);
isa_ok $json_obj, 'HASH';
is $json_obj->{test1}, 1;
is $json_obj->{test2}, 2;


use Test::More tests => 15;
use Egg::Helper::VirtualTest;

my $v= Egg::Helper::VirtualTest->new;
   $v->prepare(
     controller=> { egg_includes=> [qw/JSON/] },
     create_files=> [$v->yaml_load( join '', <DATA> )],
     config=> { json_data=> '<$e.root>/etc/json.code' },
     );

my $json_obj= { aaa=> 'bbb', ccc=> 'ddd' };

ok my $e= $v->egg_pcomp_context;
can_ok $e, qw/obj2json json2obj json get_json/;
ok my $json_js  = $e->obj2json($json_obj);
ok my $json_hash= $e->json2obj($json_js);
isa_ok $json_hash, 'HASH';
is $json_hash->{aaa}, 'bbb';
is $json_hash->{ccc}, 'ddd';
ok my $json= $e->json;
isa_ok $json, 'JSON';
ok my $result= $e->get_json($e->config->{json_data});
is $result->is_success, 1;
ok my $obj= $result->obj;
isa_ok $obj, 'HASH';
is $obj->{foo}, 12345;
is $obj->{boo}, 23456;


__DATA__
filename: etc/json.code
value: |
  {"foo":12345,"boo":23456}

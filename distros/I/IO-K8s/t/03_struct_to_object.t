#!/usr/bin/env perl

use Test::More;
use Test::Exception;
use IO::K8s;

my $io = IO::K8s->new;

{
  my $obj = $io->struct_to_object(
    'IO::K8s::Api::Core::V1::Container',
    {
      name => 'container_name',
      env => [
        { name => 'STR_ENV', value => 'STRVALUE' },
        { name => 'INT_ENV', value => '3306' },
        { name => 'ENV_FROM', valueFrom => { secretKeyRef => { name => 'mystore', key => 'key' } } },
      ],
      ports => [
        { hostPort => '4607' },
      ],
      command => [ 'c1', 'c2', 'c3' ],
      tty => 1,
    }
  );
  
  isa_ok($obj, 'IO::K8s::Api::Core::V1::Container');
  cmp_ok($obj->name, 'eq', 'container_name');
  isa_ok($obj->env->[0], 'IO::K8s::Api::Core::V1::EnvVar');
  cmp_ok($obj->env->[0]->name, 'eq', 'STR_ENV');
  cmp_ok($obj->env->[0]->value, 'eq', 'STRVALUE');
  cmp_ok($obj->env->[1]->name, 'eq', 'INT_ENV');
  cmp_ok($obj->env->[1]->value, 'eq', '3306');
  cmp_ok($obj->env->[2]->name, 'eq', 'ENV_FROM');
  cmp_ok($obj->env->[2]->valueFrom->secretKeyRef->name, 'eq', 'mystore');
  cmp_ok($obj->env->[2]->valueFrom->secretKeyRef->key, 'eq', 'key');
  
  isa_ok($obj->ports->[0], 'IO::K8s::Api::Core::V1::ContainerPort');
  cmp_ok($obj->ports->[0]->hostPort, '==', 4607);
  cmp_ok($obj->tty, '==', 1);
  cmp_ok($obj->command->[0], 'eq', 'c1');
  
  # Turn that into a JSON
  my $json = $io->object_to_json($obj);
  
  like($json, qr|"name":"container_name"|);
  like($json, qr|"value":"3306"|);
  like($json, qr|"hostPort":4607|);
  like($json, qr|"tty":true|);
  like($json, qr|\{"name":"INT_ENV","value":"3306"\}|);
  like($json, qr|"command":\["c1","c2","c3"\]|);
}

{
  my $obj = $io->struct_to_object(
    'IO::K8s::Api::Core::V1::Service',
    {
      kind => 'Service',
      apiVersion => 'v1',
      metadata => {
        name => 'svc_name',
      },
      spec => {
        selector => {
          app => "MyApp",
        },
        ports => [
          { port => 80, protocol => 'TCP', targetPort => 8022 },
        ]
      },
    }
  );
 
  isa_ok($obj, 'IO::K8s::Api::Core::V1::Service');
  isa_ok($obj->spec, 'IO::K8s::Api::Core::V1::ServiceSpec');
  isa_ok($obj->spec->ports->[0], 'IO::K8s::Api::Core::V1::ServicePort');

  my $json = $io->object_to_json($obj);
  diag $json;

  like($json, qr|"metadata":\{"name":"svc_name"\}|);
  like($json, qr|"apiVersion":"v1"|);
  like($json, qr|"targetPort":8022|);
}

{
  my $obj = $io->struct_to_object(
    'IO::K8s::Api::Extensions::V1beta1::ReplicaSet',
    {
      kind => 'ReplicaSet',
      apiVersion => 'extensions/v1beta1',
      metadata => {
        name => 'repl_name',
      },
      spec => {
        replicas => 3,
        template => {
          metadata => {
            labels => {
              label1 => 'value1',
              label2 => 'value2',
            }
          },
          spec => {
            containers => [{
              image => 'image1',
              resources => {
                requests => {
                  cpu => '250m',
                  memory => '64Mi',
                },
                limits => {
                  cpu => '500m',
                  memory => '128Mi',
                },
              },
              volumeMounts => [
                { name => 'xxx', mountPath => '/tmp/mount1/', readOnly => 'true' },
                { name => 'xxx2', mountPath => '/tmp/mount2/', readOnly => 1 },
              ],
            }],
            volumes => [
              { name => 'volname', secret => { secretName => 'volsecret' } },
            ]
          }
        }
      },
    }
  );

  isa_ok($obj, 'IO::K8s::Api::Extensions::V1beta1::ReplicaSet');
  isa_ok($obj->spec->template->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');
  isa_ok($obj->spec->template->spec->volumes->[0], 'IO::K8s::Api::Core::V1::Volume');
  cmp_ok($obj->spec->template->spec->volumes->[0]->name, 'eq', 'volname');
  cmp_ok($obj->spec->template->spec->volumes->[0]->secret->secretName, 'eq', 'volsecret');
  isa_ok($obj->spec->template->spec->containers->[0], 'IO::K8s::Api::Core::V1::Container');
  isa_ok($obj->spec->template->spec->containers->[0]->resources, 'IO::K8s::Api::Core::V1::ResourceRequirements');
  cmp_ok($obj->spec->template->spec->containers->[0]->resources->requests->{ cpu }, 'eq', '250m');
  cmp_ok($obj->spec->template->spec->containers->[0]->resources->limits->{ cpu }, 'eq', '500m');
 
  my $json = $io->object_to_json($obj);
  diag $json;

  like($json, qr|\{"mountPath":"/tmp/mount1/","name":"xxx","readOnly":true\}|);
  like($json, qr|\{"mountPath":"/tmp/mount2/","name":"xxx2","readOnly":true\}|);

}



{
  lives_ok(sub {
    my $obj = $io->struct_to_object(
      'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
      {
        creationTimestamp => undef,
        labels => {
          label1 => 'value1'
        },
      }
    );
  }, 'ObjectMeta with creationTimestamp undef');
}
 
{
  my $obj = $io->json_to_object(
    'IO::K8s::Api::Core::V1::Service',
    '{"kind":"Service"}'
  );
  isa_ok($obj, 'IO::K8s::Api::Core::V1::Service');
  cmp_ok($obj->kind, 'eq', 'Service'); 
}

done_testing;

#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Kubectl::CLIWrapper;

{
  my $control = Kubectl::CLIWrapper->new(namespace => 'ns1');
  my $command = join ' ', $control->command_for('create', 'pod');
  note $command;
  cmp_ok($command, 'eq', 'kubectl --namespace=ns1 create pod');
}

{
  my $control = Kubectl::CLIWrapper->new(
    namespace  => 'ns1',
    server     => 'https://server1.example.com',
    username   => 'u1',
    password   => 'p1',
    kubeconfig => './foo',
  );
  my $command = join ' ', $control->command_for('create', 'pod');
  note $command;
  like($command, qr/--username=u1/);
  like($command, qr/--password=p1/);
  like($command, qr|--server=https://server1.example.com|);
  like($command, qr/--namespace=ns1/);
  like($command, qr|--kubeconfig=\./foo\b|);
}

{
  my $control = Kubectl::CLIWrapper->new(
    namespace    => 'ns1',
    server       => 'https://server1.example.com',
    token        => 't1',
  );
  my $command = join ' ', $control->command_for('create', 'pod');
  note $command;
  like($command, qr/--namespace=ns1/);
  like($command, qr|--server=https://server1.example.com|);
  like($command, qr/--token=t1/);
}

{
  my $token_num = 1;
  my $control = Kubectl::CLIWrapper->new(
    namespace    => 'ns1',
    server       => 'https://server1.example.com',
    token        => sub { sprintf("t%s", $token_num++) }
  );
  my $command1 = join ' ', $control->command_for('create', 'pod');
  note $command1;
  like($command1, qr/--namespace=ns1/);
  like($command1, qr|--server=https://server1.example.com|);
  like($command1, qr/--token=t1/);

  my $command2 = join ' ', $control->command_for('create', 'pod');
  note $command2;
  like($command2, qr/--namespace=ns1/);
  like($command2, qr|--server=https://server1.example.com|);
  like($command2, qr/--token=t2/);
}

{
  my $ok = Kubectl::CLIWrapper->new(
    kubectl => 't/fake_kubectl/ok',
    namespace => 'x',
  );
  my $r1 = $ok->run('stub');
  cmp_ok($r1->success, '==', 1);
  cmp_ok($r1->output, 'eq', '');
  ok(not(defined $r1->json));
  my $r2 = $ok->input('stub', 'stub');
  cmp_ok($r2->success, '==', 1);
  cmp_ok($r2->output, 'eq', '');
  ok(not(defined $r2->json));
}

{
  my $error = Kubectl::CLIWrapper->new(
    kubectl => 't/fake_kubectl/error',
    namespace => 'x',
  );
  my $r1 = $error->run('stub');
  cmp_ok($r1->success, '==', 0);
  cmp_ok($r1->output, 'eq', '');
  ok(not(defined $r1->json));
  my $r2 = $error->input('stub', 'stub');
  cmp_ok($r2->success, '==', 0);
  cmp_ok($r2->output, 'eq', '');
  ok(not(defined $r2->json));
}

{
  my $json = Kubectl::CLIWrapper->new(
    kubectl => 't/fake_kubectl/ok_with_result',
    namespace => 'x',
  );
  my $r1 = $json->run('stub');
  cmp_ok($r1->success, '==', 1);
  ok(not(defined $r1->json));
  like($r1->output, qr/apiVersion/);

  my $r2 = $json->input('stub', 'stub');
  cmp_ok($r2->success, '==', 1);
  ok(not(defined $r2->json));
  like($r2->output, qr/apiVersion/);

  my $r3 = $json->json('stub');
  cmp_ok($r3->success, '==', 1);
  ok(ref($r3->json) eq 'HASH');
  cmp_ok($r3->json->{ apiVersion }, 'eq', 'v1');
  ok(ref($r3->json->{ items }) eq 'ARRAY');
  like($r2->output, qr/apiVersion/);
}

done_testing;

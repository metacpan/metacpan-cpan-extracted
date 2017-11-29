use strict;
use Test::More 0.98;
use File::Spec;
use GraphQL::Execution qw(execute);
use Data::Dumper;
use JSON::MaybeXS;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

use_ok 'GraphQL::Plugin::Convert::OpenAPI';

sub run_test {
  my ($args, $expected) = @_;
  my $got = execute(@$args);
  is_deeply $got, $expected or diag nice_dump($got);
}

sub nice_dump {
  my ($got) = @_;
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  Dumper $got;
}

my $converted = GraphQL::Plugin::Convert::OpenAPI->to_graphql(
  't/cpantesters-v3.json'
);

subtest 'execute pk + deeper query' => sub {
  my $doc = <<'EOF';
{
  v3_report_get(id: "a35ce723-6bf8-1014-858b-1fdf904013f2") {
    id
    created
    reporter {
      name
    }
  }
}
EOF
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 3, $converted->{resolver},
    ],
    {
      data => {
        v3_report_get => {
          created => '2017-11-16T13:32:21Z',
          id => 'a35ce723-6bf8-1014-858b-1fdf904013f2',
          reporter => { name => 'Alexandr Ciornii (CHORNY)' },
        },
      }
    }
  );
};

done_testing;

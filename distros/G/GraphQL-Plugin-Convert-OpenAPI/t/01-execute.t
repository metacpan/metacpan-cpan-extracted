use strict;
use Test::More 0.98;
use File::Spec;
use GraphQL::Execution qw(execute);
use Data::Dumper;
use JSON::MaybeXS;
use Mojolicious::Plugin::GraphQL qw(promise_code);
use Test::Snapshot;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

use_ok 'GraphQL::Plugin::Convert::OpenAPI';

sub run_test {
  my ($args) = @_;
  my @args = @$args;
  $args[7] = promise_code();
  my $got = execute(@args);
  my @result;
  $got->then(sub { @result = @_; });
  $got->wait;
  $got = $result[0];
  is_deeply_snapshot $got, 'execute' or diag nice_dump($got);
}

sub nice_dump {
  my ($got) = @_;
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  Dumper $got;
}

my $converted = GraphQL::Plugin::Convert::OpenAPI->to_graphql(
  't/01-corpus.json'
);

my $doc = <<'EOF';
{
  v3_report_get(id: "a35ce723-6bf8-1014-858b-1fdf904013f2") {
    id
    created
    reporter {
      name
    }
    environment {
      toolchain {
        key
        value
      }
    }
  }
}
EOF
run_test(
  [
    $converted->{schema}, $doc, $converted->{root_value},
    (undef) x 3, $converted->{resolver},
  ],
);

done_testing;

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
  #open my $fh, '>', 'tf'; print $fh nice_dump($got); # uncomment to regenerate
  is_deeply $got, $expected or diag nice_dump($got);
}

sub nice_dump {
  my ($got) = @_;
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  Dumper $got;
}

my $converted = GraphQL::Plugin::Convert::OpenAPI->to_graphql(
  't/04-corpus.json'
);
my $expected = eval join '', <DATA>;

my $doc = <<'EOF';
{
  getPetById(petId: 457453558) {
    category {
      id
      name
    }
    name
    photoUrls
  }
}
EOF
run_test(
  [
    $converted->{schema}, $doc, $converted->{root_value},
    (undef) x 3, $converted->{resolver},
  ],
  $expected,
);

done_testing;

__DATA__
{
  'data' => {
    'getPetById' => {
      'category' => {
        'id' => 1331493758,
        'name' => 'dog'
      },
      'name' => 'hello kity with form updated',
      'photoUrls' => [
        'http://foo.bar.com/1',
        'http://foo.bar.com/2'
      ]
    }
  }
}

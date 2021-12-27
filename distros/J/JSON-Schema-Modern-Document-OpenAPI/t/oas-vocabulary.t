use strict;
use warnings;
use strictures 2;
use experimental qw(signatures postderef);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::JSON::Schema::Acceptance;
use Test::File::ShareDir -share => { -dist => { 'JSON-Schema-Modern-Document-OpenAPI' => 'share' } };
use File::ShareDir 'dist_dir';
use Path::Tiny;
use JSON::Schema::Modern;
use JSON::Schema::Modern::Document::OpenAPI;

my $accepter = Test::JSON::Schema::Acceptance->new(
  include_optional => 1,
  verbose => 1,
  test_schemas => -d '.git' || $ENV{AUTHOR_TESTING},
  specification => 'draft2020-12',
  include_optional => 0,
  test_dir => 't/oas-invalid-schemas',
);

my $js = JSON::Schema::Modern->new(
  specification_version => 'draft2020-12',
  validate_formats => 1,
);

# construct a minimal document in order to get the vocabulary and formats added
my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
  evaluator => $js,
  schema => {
    openapi => '3.1.0',
    info => {
      title => 'my title',
      version => '1.2.3',
    },
    paths => {},
  },
);

$accepter->acceptance(
  $ENV{NO_TODO} ? () : ( todo_tests => [
    # requires bigint/bignum support in JSON::Schema::Modern
    { file => 'formats.json', group_description => 'int64 format', test_description => [ 'too small', 'upper boundary', 'too large' ] }
  ] ),
  validate_data => sub ($schema, $instance_data) {
    my $result = $js->evaluate($instance_data, $schema);

    my $encoder = JSON::MaybeXS->new(allow_nonref => 1, utf8 => 0, convert_blessed => 1, canonical => 1, pretty => 1);
    $encoder->indent_length(2) if $encoder->can('indent_length');
    note 'result: ', $encoder->encode($result);

    warn('evaluation generated an exception: '.$encoder->encode($_))
      foreach
        grep +($_->{error} =~ /^EXCEPTION/),
          $result->TO_JSON->{errors}->@*;

    $result;
  },
  @ARGV ? (tests => { file => \@ARGV }) : (),
);

done_testing;

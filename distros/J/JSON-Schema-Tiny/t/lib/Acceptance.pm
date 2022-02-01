use strict;
use warnings;
# no package, so things defined here appear in the namespace of the parent.

use 5.020;
use experimental qw(signatures postderef);
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Path::Tiny;

use if $ENV{AUTHOR_TESTING}, 'Test::Warnings' => ':fail_on_warning'; # hooks into done_testing unless overridden
use Test::JSON::Schema::Acceptance 1.014;
use JSON::Schema::Tiny;

BEGIN {
  foreach my $env (qw(AUTHOR_TESTING AUTOMATED_TESTING EXTENDED_TESTING NO_TODO TEST_DIR NO_SHORT_CIRCUIT)) {
    note $env.': '.($ENV{$env}//'');
  }
  note '';
}

sub acceptance_tests (%options) {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $accepter = Test::JSON::Schema::Acceptance->new(
    include_optional => 1,
    verbose => 1,
    test_schemas => 0,
    $options{acceptance}->%*,
    $ENV{TEST_DIR} ? (test_dir => $ENV{TEST_DIR})
      : $ENV{TEST_PREFIXDIR} ? (test_dir => path($ENV{TEST_PREFIXDIR}, 'tests', $options{acceptance}{specification})) : (),
  );
  $accepter->_json_decoder->allow_bignum; # TODO: switch to public accessor with TJSA 1.015

  my $js = JSON::Schema::Tiny->new($options{evaluator}->%*);
  my $js_short_circuit = $ENV{NO_SHORT_CIRCUIT} || JSON::Schema::Tiny->new($options{evaluator}->%*, short_circuit => 1);

  my $encoder = JSON::MaybeXS->new(allow_nonref => 1, utf8 => 0, canonical => 1, pretty => 1);
  $encoder->indent_length(2) if $encoder->can('indent_length');

  $accepter->acceptance(
    validate_data => sub ($schema, $instance_data) {
      my $result = $js->evaluate($instance_data, $schema);
      my $result_short = $ENV{NO_SHORT_CIRCUIT} || $js_short_circuit->evaluate($instance_data, $schema);

      note 'result: ', $encoder->encode($result);
      note 'short-circuited result: ', ($encoder->encode($result_short) ? 'true' : 'false')
        if not $ENV{NO_SHORT_CIRCUIT} and ($result->{valid} xor $result_short->{valid});

      die 'results inconsistent between short_circuit = false and true'
        if not $ENV{NO_SHORT_CIRCUIT} and ($result->{valid} xor $result_short->{valid});

      # if any errors contain an exception, generate a warning so we can be sure
      # to count that as a failure (an exception would be caught and perhaps TODO'd).
      # (This might change if tests are added that are expected to produce exceptions.)
      foreach my $r ($result, ($ENV{NO_SHORT_CIRCUIT} ? () : $result_short)) {
        warn('evaluation generated an exception: '.$encoder->encode($_))
          foreach
            grep +($_->{error} =~ /^EXCEPTION/
                && $_->{error} !~ /but short_circuit is enabled/            # unevaluated*
                && $_->{error} !~ /(max|min)imum value is not a number$/),  # optional/bignum.json
              $r->{errors}->@*;
      }

      $result->{valid};
    },
    @ARGV ? (tests => { file => \@ARGV }) : (),
    ($options{test} // {})->%*,
  );

  path('t/results/'.$options{output_file})->spew_utf8($accepter->results_text)
    if -d '.git' or $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};
}
1;

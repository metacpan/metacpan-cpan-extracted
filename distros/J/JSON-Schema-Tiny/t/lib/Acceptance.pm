use strict;
use warnings;
# no package, so things defined here appear in the namespace of the parent.

use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use List::Util 1.50 'head';
use Path::Tiny;

BEGIN {
  my @variables = qw(AUTHOR_TESTING AUTOMATED_TESTING EXTENDED_TESTING);

  plan skip_all => 'These tests may fail if the test suite continues to evolve! They should only be run with '
      .join(', ', map $_.'=1', head(-1, @variables)).' or '.$variables[-1].'=1'
    if not -d '.git' and not grep $ENV{$_}, @variables;
}

use if $ENV{AUTHOR_TESTING}, 'Test::Warnings' => ':fail_on_warning';
use Test::JSON::Schema::Acceptance 1.007;
use JSON::Schema::Tiny 'evaluate';

sub acceptance_tests {
  my (%options) = @_;

  my $version = delete $options{specification};

  my $accepter = Test::JSON::Schema::Acceptance->new(
    $ENV{TEST_DIR}
      ? (test_dir => $ENV{TEST_DIR})
      : (
        specification => $version,
        include_optional => 1,
        skip_dir => 'optional/format',
      ),
    verbose => 1,
  );

  my $encoder = JSON::MaybeXS->new(allow_nonref => 1, utf8 => 0, convert_blessed => 1, canonical => 1, pretty => 1);
  $encoder->indent_length(2) if $encoder->can('indent_length');

  $accepter->acceptance(
    validate_data => sub {
      my ($schema, $instance_data) = @_;
      my $result = evaluate($instance_data, $schema);
      my $result_short = $ENV{NO_SHORT_CIRCUIT} || do {
        local $JSON::Schema::Tiny::SHORT_CIRCUIT = 1;
        evaluate($instance_data, $schema);
      };

      note 'result: ', $encoder->encode($result);

      note 'short-circuited result: ', ($encoder->encode($result_short) ? 'true' : 'false')
        if not $ENV{NO_SHORT_CIRCUIT} and ($result->{valid} xor $result_short->{valid});

      die 'results inconsistent between short_circuit = false and true'
        if not $ENV{NO_SHORT_CIRCUIT} and ($result->{valid} xor $result_short->{valid});


      # if any errors contain an exception, generate a warning so we can be sure
      # to count that as a failure (an exception would be caught and perhaps TODO'd).
      # (This might change if tests are added that are expected to produce exceptions.)
      foreach my $r ($result, ($ENV{NO_SHORT_CIRCUIT} ? () : $result_short)) {
        map warn('evaluation generated an exception: '.$encoder->encode($_)),
          grep +($_->{error} =~ /^EXCEPTION/
              && $_->{error} !~ /but short_circuit is enabled/            # unevaluated*
              && $_->{error} !~ /(max|min)imum value is not a number$/),  # optional/bignum.json
            @{$r->{errors}};
      }

      $result->{valid};
    },
    @ARGV ? (tests => { file => \@ARGV }) : (),
    %options,
  );

  path($ENV{RESULTS_FILE} // ('t/results/'.$version.'.txt'))->spew_utf8($accepter->results_text)
    if -d '.git' or $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};
}

END {
diag <<DIAG

###############################

Attention CPANTesters: you do not need to file a ticket when this test fails. I will receive the test reports and act on it soon. thank you!

###############################
DIAG
  if not Test::Builder->new->is_passing;
}

1;

# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings' => ':fail_on_warning';
use Test::JSON::Schema::Acceptance 0.993;
use JSON::Schema::Tiny 'evaluate';

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/additional-tests', verbose => 1);

plan skip_all => 'no tests in this directory to test' if not @{$accepter->_test_data};

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
        grep $_->{error} =~ /^EXCEPTION/
            && $_->{error} !~ /but short_circuit is enabled/,         # unevaluated*
          @{$r->{errors}};
    }

    $result->{valid};
  },
  @ARGV ? (tests => { file => \@ARGV }) : (),
  # optional prereqs
  todo_tests => [
    eval { require Email::Address::XS; 1 } ? () : { file => 'format-idn-email.json' },
  ],
);

done_testing;

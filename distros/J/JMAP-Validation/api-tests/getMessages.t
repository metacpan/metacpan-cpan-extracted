#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Tester;
use JMAP::Validation::Checks::Error;
use JMAP::Validation::Checks::Message;
use Test2::Bundle::Extended;

my (
  %ACCOUNT,
  $STATE,
  @TESTS,
);

init();
do_tests();
done_testing();

sub _define_error_tests {
}

sub _define_good_tests {
}

sub do_tests {
  _reset_state();

  foreach my $test (@TESTS) {
    my $request_args = $test->{is_error}
      ? _build_error_request($test)
      : _build_good_request($test);

    my $result = $ACCOUNT{jmap}->request([["getMessages", $request_args]])
      or die "Error getting contact groups\n";

    if ($test->{is_error}) {
      my $error = $result && $result->sentence(0) && $result->sentence(0)->as_struct();

      is($error, $JMAP::Validation::Checks::Error::is_error);
      is($error, _build_error_response($test));

      next;
    }

    my $messages = $result && $result->sentence(0) && $result->sentence(0)->arguments();

    is($messages, $JMAP::Validation::Checks::Message::is_messages);
    is($messages, _build_good_response($test));
  }
}

sub init {
  unless (scalar(@ARGV) == 1) {
    # TODO: add athentication via access token
    die "usage: $0 <accountId:jmap-account-url>\n";
  }

  my ($accountId, $uri) = $ARGV[0] =~ /([^:]+):(.*)/;

  unless ($accountId and $uri) {
    die "Parameters are not in the following format <accountId:jmap-account-uri>\n";
  }

  %ACCOUNT = (
    accountId => $accountId,
    jmap      => JMAP::Tester->new({ jmap_uri => $uri }),
    messages  => [ map { JMAP::Validation::Generators::Message::generate() } 1..6 ],
  );

  _define_error_tests();
  _define_good_tests();
}

sub _build_error_request {
}

sub _build_good_request {
}

sub _build_error_response {
}

sub _build_good_response {
}

sub _reset_state {
}

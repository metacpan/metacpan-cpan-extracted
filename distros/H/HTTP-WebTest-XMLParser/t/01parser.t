use lib qw(blib blib/lib);
use HTTP::WebTest::XMLParser;
use HTTP::WebTest::SelfTest;
use Test::More tests => 13;


my $xml;
{
  open(FH, 't/testdefs.xml') || die $!;
  local $/;
  $xml = <FH>;
}

{
  my ($tests, $opts) = HTTP::WebTest::XMLParser->parse($xml);

  ok(@$tests == 5);
  ok($tests->[0]{test_name} eq 'Yahoo Home');
  ok($tests->[0]{text_require}[0] eq '</html>');
  ok($tests->[0]{text_require}[1] eq 'Yahoo!');
  ok($tests->[1]{url} eq 'http://slashdot.org/');
  ok($tests->[2]{click_link} eq '.*Read More\.\.\..*');
  ok($tests->[3]{text_forbid}[0] eq 'Internal Server Error');

  # code ref
  ok(&{ $tests->[4]{coderef} } eq 'this is returned from code');

  # global options from 'param' section
  ok($opts->{plugins}[1] eq '::Click');
}

my @ERRS = (
  "WebTest definition should be version 1.0 or newer",
  "Invalid named list in list context",
  'No child elements allowed for element',
  'Invalid character data in "list" element',
);
for my $test (1..scalar @ERRS) {
  {
    my $errfile = "t/err$test.xml";
    open(FH, $errfile) || die "$errfile: ", $!;
    local $/;
    $xml = <FH>;
    eval {
      my ($tests, $opts) = HTTP::WebTest::XMLParser->parse($xml);
    };
    ok(index($@, $ERRS[$test - 1]) == 0);
    print "exception: $@\n" if $ENV{TEST_VERBOSE};
  }
}

use lib qw(blib blib/lib);
use HTTP::WebTest::XMLParser;
use HTTP::WebTest::SelfTest;
use Test::More tests => 4;


{
  open(FH, 't/testdefs.xml') || die $!;
  local $/;
  my $xml = <FH>;
  my ($tests, $opts) = HTTP::WebTest::XMLParser->parse($xml);

  # sanity check
  ok(&{ $tests->[4]{coderef} } eq 'this is returned from code');

  # test writer without code ref
  my $out = HTTP::WebTest::XMLParser->as_xml($tests, $opts, { nocode => 1 });
  # from selftest:
  compare_output(output_ref => \$out,
                 check_file => 't/testdefs_out.xml',
                );
}

# test with Perl code

SKIP: {
  eval {
    local $SIG{__DIE__};
    require B::Deparse; # as of Perl 5.6
    die "B::Deparse 0.60 or newer needed" if ($B::Deparse::VERSION < 0.6);
  };
  skip 'B::Deparse not available', 2 unless ($@ eq '');

  open(FH, 't/simple.xml') || die $!;
  local $/;
  my $xml = <FH>;
  my ($tests, $opts) = HTTP::WebTest::XMLParser->parse($xml);

  # sanity check
  ok(ref $tests->[0]{regex_forbid}[6] eq 'CODE');

  my $out = HTTP::WebTest::XMLParser->as_xml($tests, $opts);
  # from selftest:
  compare_output(output_ref => \$out,
                   check_file => 't/simple_out.xml',
                );
};


#!/usr/bin/perl -w
use lib qw(./blib/lib ./t/lib);
use Test;
BEGIN { plan tests => 4; }

use HTTP::WebTest 2.0;                 # from HTTP::WebTest v 2.xx
use HTTP::WebTest::SelfTest;           # from HTTP::WebTest v 2.xx
use HTTP::WebTest::Plugin::XMLReport;  # from blib/lib


my $WEBTEST = HTTP::WebTest->new;

my $deffilter = sub {
  $_[0] =~ s/\s*date="[^"]+"/ date="A_DATESTAMP"/g;
  $_[0] =~ s/\s*url="[^"]+"/ url="A_URL"/g;
};

# 1 - do some real request
{
    my $tests = [
        {
          test_name          => 'xmltest',
          url                => 't/in.html',
          text_require       => [ 'SEE_ALSO', '</html>', 'This SHOULD fail' ],
          text_forbid        => [ 'Internal Server Error' ],
        } ];
    my $opts = { plugins     => ['::XMLReport', '::FileRequest'],
                 default_report => 'no' };
    check_webtest(webtest    => $WEBTEST,
                  tests      => $tests,
                  out_filter => $deffilter,
                  opts       => $opts,
                  check_file => 't/test.out/out.xml');
}

# 2 - test with DTD - validate separately if you're paranoid enough
{
    my $tests = [
        {
          test_name          => 'dtd-test',
          url                => 't/in.html',
          text_require       => [ 'SEE_ALSO', '</html>' ],
          text_forbid        => [ 'Internal Server Error' ],
        } ];
    my $opts = { plugins     => ['::XMLReport', '::FileRequest'],
                 xml_report_dtd => 'yes',
                 default_report => 'no' };
    check_webtest(webtest    => $WEBTEST,
                  tests      => $tests,
                  out_filter => $deffilter,
                  opts       => $opts,
                  check_file => 't/test.out/out-dtd.xml');
}

# 3 - missing wtscript param test_name
{
    my $tests = [
        {
          url                => 't/in.html',
          text_require       => [ 'SEE_ALSO', '</html>' ],
          text_forbid        => [ 'Internal Server Error' ],
        } ];
    my $opts = { plugins     => ['::XMLReport', '::FileRequest'],
                 xml_report_dtd => 'yes',
                 default_report => 'no' };
    check_webtest(webtest    => $WEBTEST,
                  tests      => $tests,
                  out_filter => $deffilter,
                  opts       => $opts,
                  check_file => 't/test.out/out-no-name.xml');
}

# 4 - cooperation with uninmplemented params (normally used with default report)
{
    my $tests = [
        {
          url                => 't/in.html',
	  test_name          => 'missing-opts',
          show_headers       => 'yes',
          show_html          => 'yes',
          show_cookies       => 'yes',
          text_forbid        => [ 'Internal Server Error' ],
        } ];
    my $opts = { plugins     => ['::XMLReport', '::FileRequest'],
                 default_report => 'no' };
    check_webtest(webtest    => $WEBTEST,
                  tests      => $tests,
                  out_filter => $deffilter,
                  opts       => $opts,
                  check_file => 't/test.out/out-missing-opts.xml');
}

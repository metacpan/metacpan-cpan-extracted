use strict;
use warnings;
use Test::More;

use lib 'lib';
use FacialHarmonyAI::SiteKit qw(
  BASE
  analysis_url
  pricing_url
  features_url
  faq_url
  report_url
  dashboard_url
  blog_url
  is_valid_report_id
  site_metadata
);

is(BASE, 'https://facialharmonyai.com', 'base URL');
is(analysis_url(), 'https://facialharmonyai.com/analyze', 'analysis URL');
is(pricing_url(), 'https://facialharmonyai.com/#pricing', 'pricing URL');
is(features_url(), 'https://facialharmonyai.com/#features', 'features URL');
is(faq_url(), 'https://facialharmonyai.com/#faq', 'FAQ URL');
is(report_url('abc123'), 'https://facialharmonyai.com/report/abc123', 'report URL');
is(dashboard_url(), 'https://facialharmonyai.com/dashboard', 'dashboard URL');
is(blog_url(), 'https://facialharmonyai.com/blog', 'blog URL');

ok(is_valid_report_id('abc12345'), 'valid report id');
ok(!is_valid_report_id('ab'), 'short report id invalid');
ok(!is_valid_report_id('with-hyphen'), 'non-alphanumeric report id invalid');

my $metadata = site_metadata();
is($metadata->{name}, 'FacialHarmonyAI', 'metadata name');
is($metadata->{homepage}, 'https://facialharmonyai.com', 'metadata homepage');
is($metadata->{canonical_pages}->{analysis}, analysis_url(), 'metadata analysis URL');

eval { report_url('') };
like($@, qr/non-empty string/, 'empty report id dies');

done_testing();


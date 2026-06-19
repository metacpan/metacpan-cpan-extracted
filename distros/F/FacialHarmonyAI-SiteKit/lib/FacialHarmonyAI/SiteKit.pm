package FacialHarmonyAI::SiteKit;

use strict;
use warnings;
use URI::Escape qw(uri_escape);
use Exporter qw(import);

our $VERSION = '0.1.0';
our @EXPORT_OK = qw(
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

use constant BASE => 'https://facialharmonyai.com';

sub analysis_url { return BASE . '/analyze' }
sub pricing_url  { return BASE . '/#pricing' }
sub features_url { return BASE . '/#features' }
sub faq_url      { return BASE . '/#faq' }
sub dashboard_url { return BASE . '/dashboard' }
sub blog_url { return BASE . '/blog' }

sub report_url {
    my ($report_id) = @_;
    die 'report_id must be a non-empty string' unless defined $report_id && length $report_id;
    return BASE . '/report/' . uri_escape($report_id);
}

sub is_valid_report_id {
    my ($report_id) = @_;
    return defined $report_id && $report_id =~ /\A[A-Za-z0-9]{4,64}\z/ ? 1 : 0;
}

sub site_metadata {
    return {
        name => 'FacialHarmonyAI',
        homepage => BASE,
        description => 'AI-powered facial analysis and coaching platform',
        canonical_pages => {
            analysis => analysis_url(),
            pricing => pricing_url(),
            features => features_url(),
            faq => faq_url(),
            dashboard => dashboard_url(),
            blog => blog_url(),
        },
        tags => [qw(facial-analysis ai-coaching facial-harmony url-helpers)],
    };
}

1;

__END__

=head1 NAME

FacialHarmonyAI::SiteKit - URL helpers and metadata for FacialHarmonyAI

=head1 SYNOPSIS

  use FacialHarmonyAI::SiteKit qw(analysis_url report_url site_metadata);

  my $upload = analysis_url();
  my $report = report_url('abc123');
  my $meta = site_metadata();

=head1 DESCRIPTION

This small helper exposes canonical FacialHarmonyAI links and report URL builders.

Website: L<https://facialharmonyai.com>

=head1 LICENSE

MIT


#!/usr/bin/env perl

use Test::More;
use Gcis::Client;
use Data::Dumper;
use v5.14;

unless ($ENV{GCIS_DEV_URL}) {
    plan skip_all => "set GCIS_DEV_URL to run live tests";
}

my $c = Gcis::Client->connect(url => $ENV{GCIS_DEV_URL});

ok $c->post(
  '/report',
  {
    identifier       => 'my-new-report',
    title            => "awesome report",
    frequency        => "1 year",
    summary          => "this is a great report",
    report_type_identifier => "report",
    publication_year => '2000',
    url              => "http://example.com/report.pdf",
  }
);

# Add a chapter
ok $c->post(
    "/report/my-new-report/chapter",
    {
        report_identifier => "my-new-report",
        identifier        => "my-chapter-identifier",
        title             => "Some Title",
        number            => 12,
        sort_key          => 100,
        doi               => '10.1234/567',
        url               => 'http://example.com/report/'
    }
);

my @rpt = $c->get('/report');
ok @rpt >= 1, "got some reports";

my $this = $c->get('/report/my-new-report');
is ($this->{identifier}, 'my-new-report', 'got identifier');

ok $c->delete('/report/my-new-report/chapter/my-chapter-identifier');
ok $c->delete('/report/my-new-report');

done_testing;


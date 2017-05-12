#!/usr/bin/perl
use strict;
use warnings;
use Web::Scraper;
use YAML::Syck qw(Dump LoadFile);
use Finance::Instrument;
my $c = Finance::Instrument->load_instrument_from_yml(shift) or die;;
my $path = $c->attr('cme_path') or exit;

my $Strp = DateTime::Format::Strptime->new(
    pattern     => '%m/%d/%Y' );

my $i = 0;
my $mcode_map = { map { $_ => ++$i } "FGHJKMNQUVXZ" =~ m/./g };

my $calendar = scraper {
    process "table.ProductTable tr" => "calendar[]" =>  scraper {
        process 'tr' => id => '@id',
        process 'span.LastLink' => 'dates[]' => 'TEXT',
    };
};
local $/;
my $uri = "http://www.cmegroup.com/trading/${path}_product_calendar_futures.html";
use URI;
my $file = shift;
my $res = $calendar->scrape( URI->new($file ? "file://$file" : $uri) )->{calendar};

for (@$res) {
    next unless $_->{id};
    $_->{id} =~ s/FUT$//g;
    my ($mcode, $myear) = $_->{id} =~ m/(\w)(\d+)$/;
    my @dates = map { $Strp->parse_datetime($_) } @{$_->{dates}};
    my ($year, $month) = ($myear + 2000, $mcode_map->{$mcode});
    my $expiry = sprintf('%04d%02d', $year, $month);
    if ($c->{contract_calendar}{$expiry}) {
        my $last = $c->{contract_calendar}{$expiry}{last_trading_day};
        if ($last ne $dates[1]->ymd) {
            warn "==> $expiry found, but last day is differnt: $last vs $dates[1]";
            next;
        }
    }
    warn "==> $expiry => ".$dates[1]->ymd;
    $c->{contract_calendar}{$expiry} = { first_trading_day => $dates[0]->ymd,
                                         last_trading_day => $dates[1]->ymd};
}

print Dump({ contract_calendar => $c->{contract_calendar} });

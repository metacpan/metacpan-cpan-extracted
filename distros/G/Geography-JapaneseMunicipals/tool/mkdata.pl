#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Date::Japanese::Era;
use Date::Simple qw/ymd/;
use Encode;
use FindBin::libs;
use Geography::JapaneseMunicipals;
use Geography::JapanesePrefectures;
use URI;
use Web::Scraper;

my $scraper = scraper {
    process '//area', 'prefectures[]' => {
        title => [ '@title', sub { /(.+)内区?市町村?$/, $1 } ],
        href => '@href'
    };
};
$scraper->user_agent->env_proxy();
my $result = $scraper->scrape(URI->new('http://www.lasdec.nippon-net.ne.jp/cms/1,0,14.html'));

my $data = { };
foreach my $prefecture(@{$result->{prefectures}}) {
    next
        unless $prefecture->{title};

    my $result = scraper {
        process '//div[@class="contentTeaser"]', date => [ 'text',
            sub {
                my $date_jp = shift;
                my ($year_jp, $month_jp, $day_jp) = /\s*(.+)年(.+)月(.+)日現在/;
                $month_jp =~ s/([\x{FF10}-\x{FF19}])/;ord($1)-0xff10/eg;
                $day_jp =~ s/([\x{FF10}-\x{FF19}])/;ord($1)-0xff10/eg;
                ymd(Date::Japanese::Era->new($year_jp)->gregorian_year, $month_jp, $day_jp);
            } ];
        process '//div[@class="contentBody"]//tbody/tr[td[1][text()!="団体コード"]',
            'municipals[]' => scraper {
                process '//td[1]', id => [ 'text' , sub { /^(\d{5})\d$/, $1 } ];
                process '//td[2]', name => 'text';
        };
    }->scrape($prefecture->{href});

    my $id =
        Geography::JapanesePrefectures->prefectures_id(
            Encode::encode('utf8', $prefecture->{title}));
    $data->{$id} = { municipals => $result->{municipals}, date => $result->{date} };

    sleep 1;
}

my @prefectures;
my $date;
foreach my $key (sort { $a <=> $b } keys %{$data}) {
    my @line;
    push @line, sprintf '    %s => {', $key;
    push @line,  '        municipals => [';
    push @line, join ",\n", map {
        sprintf "            { id => '%s', name => '%s' }", $_->{id}, $_->{name}
    } @{$data->{$key}->{municipals}};
    push @line, '        ]';
    push @line, '    }';
    push @prefectures, join "\n", @line;

    $date = $data->{$key}->{date}
        if !defined $date || $data->{$key}->{date} > $date;
}

my $version = sprintf '%s_%s', $Geography::JapaneseMunicipals::VERSION, $date->format('%Y%m%d');
my $code = join ",\n", @prefectures;

binmode STDOUT, ':utf8';
print <<DATA
package Geography::JapaneseMunicipals::Data;

use strict;
use warnings;
use utf8;

our \$VERSION = '$version';
our \$MUNICIPALS = {
$code
};

1;

__END__

=encoding utf8

=head1 NAME

Geography::JapaneseMunicipals::Data - data pack for Geography::JapaneseMunicipals.

=head1 SEE ALSO

see L<Geography::JapaneseMunicipals>

=head1 AUTHOR

Yukio Suzuki E<lt>yukio at cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
DATA

package Grizzly::Command::news;
use Grizzly -command;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)';

use Finance::Quote;
use Web::NewsAPI;
use Grizzly::Progress::Bar;

my $q = Finance::Quote->new("YahooJSON");

sub abstract { "display stock news" }

sub description { "Display the any news on the stock." }

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error("Need a symbol args") unless @$args;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    quote_info(@$args);
}

sub quote_info {
    my ($symbol) = @_;

    my $article_number = 1;

    my %quote = $q->yahoo_json($symbol);

    Grizzly::Progress::Bar->progressbar();

    my $name = $quote{ $symbol, "name" };

    my $api_key = $ENV{'NEWS_API_KEY'};

    my $newsapi = Web::NewsAPI->new( api_key => $api_key, );

    unless ($name) {
        $name = $symbol;
    }

    print "Here are the top ten headlines worldwide for $name...\n";
    print "\n";
    my $stock_news = $newsapi->everything( q => $name, pageSize => 10 );
    for my $article ( $stock_news->articles ) {
        print "$article_number: \n" . $article->title . "\n";
        print "Link: " . $article->url . "\n";
        print "Description: " . $article->description . "\n";
        print "\n";
        $article_number += 1;
    }
    print "The total number of $name articles returned: "
      . $stock_news->total_results . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Grizzly::Command::news

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    grizzly news [stock symbol]

=head1 DESCRIPTION

The news feture will output stock in formation on the inputted ticker symbol.

=head1 NAME

Grizzly::Command::news

=head1 API Key

You will need to get a free API key from L<NewsAPI|https://newsapi.org/>. Afterwards you will need to set the NEWS_API_KEY environment variable to the API key.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Nobunaga.

MIT License

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Nobunaga.

This is free software, licensed under:

  The MIT (X11) License

=cut

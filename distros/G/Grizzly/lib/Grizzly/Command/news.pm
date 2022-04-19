package Grizzly::Command::news;

# ABSTRACT: Gets the stock news for the given symbol

use Grizzly -command;
use strict;
use warnings;
use Carp;
use open ':std', ':encoding(UTF-8)';

use Finance::Quote;
use Web::NewsAPI;
use Grizzly::Progress::Bar;
use Term::ANSIColor;

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

    my $api_key = $ENV{'NEWS_API_KEY'}
      or croak
      "You need to set an API key to NEWS_API_KEY environment variable";

    my $newsapi = Web::NewsAPI->new( api_key => $api_key, );

    unless ($name) {
        $name = $symbol;
    }

    print colored( "Here are the top ten headlines worldwide for ", "blue" )
      . colored( "$name...\n", "white" );
    print "\n";
    my $stock_news = $newsapi->everything( q => $name, pageSize => 10 );
    for my $article ( $stock_news->articles ) {
        print colored( "$article_number: \n", "magenta" )
          . $article->title . "\n";
        print colored( "Link: ",        "cyan" ) . $article->url . "\n";
        print colored( "Description: ", "cyan" ) . $article->description . "\n";
        print "\n";
        $article_number += 1;
    }
    print colored( "The total number of $name articles returned: ", "blue" )
      . colored( $stock_news->total_results . "\n", "white" );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Grizzly::Command::news - Gets the stock news for the given symbol

=head1 VERSION

version 0.104

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

This software is Copyright (c) 2022 by Nobunaga.

This is free software, licensed under:

  The MIT (X11) License

=cut

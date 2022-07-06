package Grizzly::Data::Article;

# ABSTRACT:

use v5.36;
use feature qw(multidimensional);
use Carp;
use open ':std', ':encoding(UTF-8)';
use parent qw(Exporter);

use Grizzly::Progress::Bar;
use Grizzly::Data::StockInfo;
use Web::NewsAPI;
use Term::ANSIColor;

require Exporter;
our @ISA         = ("Exporter");
our @EXPORT_OK   = qw(news_info);
our @EXPORT_TAGS = ( all => [qw(news_info)], );

my $api_key = $ENV{'NEWS_API_KEY'}
  or croak "You need to set an API key to NEWS_API_KEY environment variable";

my $newsapi = Web::NewsAPI->new( api_key => $api_key, );

sub news_info {
    my ($symbol) = @_;

    my $article_number = 1;

    my %quote = stock_info($symbol);

    progressbar();

    my $name = $quote{ $symbol, "name" } || $symbol;

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

Grizzly::Data::Article - use v5.36;

=head1 VERSION

version 0.111

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Nobunaga.

This is free software, licensed under:

  The MIT (X11) License

=cut

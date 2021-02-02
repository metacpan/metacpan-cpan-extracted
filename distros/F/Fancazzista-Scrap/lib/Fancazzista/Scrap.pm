package Fancazzista::Scrap;

use 5.018004;
use strict;
use warnings;
use Fancazzista::Scrap::WebsiteScrapper;
use Fancazzista::Scrap::RedditScrapper;
use Fancazzista::Scrap::DevtoScrapper;

our $VERSION = '1.00';

sub scrapContent {
    my $config         = shift;
    my $scrapper       = new Fancazzista::Scrap::WebsiteScrapper();
    my $redditScrapper = new Fancazzista::Scrap::RedditScrapper();
    my $devtoScrapper  = new Fancazzista::Scrap::DevtoScrapper();
    my @websites       = $scrapper->scrap($config);
    my @reddits        = $redditScrapper->scrap($config);
    my @posts          = $devtoScrapper->scrap($config);
    my @list           = ( @websites, @reddits, @posts );

    return @list;
}

1;

__END__

=head1 NAME

Fancazzista::Scrap - Perl module for scrap reddit post, dev.to post, website content.

It only scrap article/post link and link text.

=head1 SYNOPSIS

    use Fancazzista::Scrap;

    my %config = (
        'websites' => [
            {
                name         => "Korben",
                url          => "https://korben.info",
                selector     => ".status-publish .entry-title",
                linkSelector => "a",
                textSelector => "a"
                limite       => 10 # optionnal 5 by default
            }
        ],
        'subreddits' => [
            {
                "name" => "javascript",
                "limit" => 10 # optionnal 5 by default
            }
        ],
        'devto' => [
            {
                "tag" => "perl",
                "limit" => 10 # optionnal 5 by default
            }
        ]
    );

    my @scrapped = Fancazzista::Scrap::scrapContent(\%config);

    @scrapped :
    [
        { 
            name => '<name>', 
            url => '<url'>, 
            articles => [
                { link => '<article-url>', text => '<article-title>' }
            ],
            from_devto => 1 # if source is dev.to
            from_website => 1 # if source if a website
            from_reddit => 1 # if source if reddit
        }
    ]   

=head1 DESCRIPTION

Fancazzista::Scrap allows to scrap website articles or subreddit posts with a config.

=head1 SEE ALSO

=head1 AUTHOR

Antoine MICELI<lt>https://miceli.click<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Antoine MICELI

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

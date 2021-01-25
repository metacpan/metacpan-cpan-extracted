package Fancazzista::Scrap;

use 5.018004;
use strict;
use warnings;
use Fancazzista::Scrap::WebsiteScrapper;
use Fancazzista::Scrap::RedditScrapper;

our $VERSION = '0.01';

sub scrapContent {
    my $config         = shift;
    my $scrapper       = new Fancazzista::Scrap::WebsiteScrapper();
    my $redditScrapper = new Fancazzista::Scrap::RedditScrapper();
    my @websites       = $scrapper->scrap($config);
    my @reddits        = $redditScrapper->scrap($config);
    my @list           = ( @websites, @reddits );

    return @list;
}

1;

__END__

=head1 NAME

Fancazzista::Scrap - Perl extension for scrap reddit or website content

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
            ]
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

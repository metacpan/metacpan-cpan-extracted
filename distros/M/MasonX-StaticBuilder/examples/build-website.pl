#!/usr/bin/perl
#
use strict;
use warnings;

use MasonX::StaticBuilder;

unless (-d 'website-static') {
    mkdir('website-static') or die "Can't make output directory: $!";
}


my $tree = MasonX::StaticBuilder->new('website-mason');
$tree->write('website-static',
    website      => 'Really Stupid News',
    author       => 'Kirrily Robert',
    author_email => 'skud@cpan.org',
    timestamp    => scalar localtime,
    news         => get_news(),
);

sub get_news {
    # imagine we're fetching from a database or something
    return [
        {
            title => 'Giant Gorilla Menaces City',
            story => 'A giant gorilla answering to the name of "King Kong" has...'
        },
        {
            title => 'Elvis Sighted in Antarctica',
            story => 'An exploration team near the South Pole yesterday reported...'
        },
    ];
}


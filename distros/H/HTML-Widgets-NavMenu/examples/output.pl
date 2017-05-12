#!/usr/bin/perl

use strict;
use warnings;

use HTML::Widgets::NavMenu;

my $nav_menu =
    HTML::Widgets::NavMenu->new(
        'path_info' => "/me/",
        'current_host' => "default",
        'hosts' =>
        {
            'default' =>
            {
                'base_url' => "http://www.hello.com/"
            },
        },
        'tree_contents' =>
        {
            'host' => "default",
            'value' => "Top 1",
            'title' => "T1 Title",
            'expand_re' => "",
            'subs' =>
            [
                {
                    'value' => "Home",
                    'url' => "",
                },
                {
                    'value' => "About Me",
                    'title' => "About Myself",
                    'url' => "me/",
                },
            ],
        },
    );

my $results = $nav_menu->render();

my $nav_menu_html = join("\n", @{$results->{'html'}});

print $nav_menu_html;


#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use HTML::Widgets::NavMenu::ToJSON;
use HTML::Widgets::NavMenu::ToJSON::Data_Persistence::YAML;

use File::Temp qw(tempdir);
use File::Spec;

use JSON::MaybeXS ( qw(decode_json) );

{
    my $tempdir = tempdir( CLEANUP => 1);

    my $yaml_fn = File::Spec->catfile($tempdir, "persistence.yaml");
    my $tree_contents =
    {
        'host' => "default",
        'text' => "Top 1",
        'title' => "T1 Title",
        'subs' =>
        [
            {
                'text' => "Home",
                'url' => "",
            },
            {
                'text' => "About Me",
                'title' => "About Myself",
                'url' => "me/",
                'expand' => { 're' => "^me/", },
                'subs' =>
                [
                    {
                        'text' => "Group Hug",
                        'url' => "me/group-hug/",
                    },
                    {
                        'text' => "Cool I/O",
                        'url' => "me/cool-io/",
                    },
                    {
                        'text' => "Resume",
                        'url' => "resume.html",
                    },
                ],
            },
            {
                'text' => "Halifax",
                'url' => "halifax/",
                'skip' => 1,
            },
            {
                'text' => "Software",
                'title' => "Open Source Software I Wrote",
                'url' => "open-source/",
                'expand' => { 're' => "^open-source/", },
                'subs' =>
                [
                    {
                        'text' => "Fooware",
                        'url' => "open-source/fooware/",
                        'skip' => 1,
                    },
                    {
                        'text' => "Condor-Man",
                        'title' => "Kwalitee",
                        'url' => "open-source/condor-man/",
                    },
                ],
            },
        ],
    };

    my $persistence =
    HTML::Widgets::NavMenu::ToJSON::Data_Persistence::YAML->new(
        {
            filename => $yaml_fn,
        }
    );

    # TEST
    ok ($persistence, "Persistence obj was initialized.");

    my $obj = HTML::Widgets::NavMenu::ToJSON->new(
        {
            data_persistence_store => $persistence,
            # The one given as input to HTML::Widgets::NavMenu
            tree_contents => $tree_contents,
        }
    );

    # TEST
    ok ($persistence, "JSON converter was initialized.");

    my $json = $obj->output_as_json( { } );
    my $as_perl = decode_json ($json);

    # TEST
    is ($as_perl->[0]->{id}, 1, "Root id is 1.");

    # TEST
    is ($as_perl->[0]->{text}, 'Home', "Root text is Home.");

    # TEST
    is ($as_perl->[0]->{url}, '', "Root url is empty.");

    # TEST
    is ($as_perl->[1]->{text}, 'About Me', '1 text');

    # TEST
    is ($as_perl->[1]->{title}, 'About Myself', '1 title');

    # TEST
    is ($as_perl->[1]->{subs}->[0]->{text}, 'Group Hug', 'subs 0 text');

    # TEST
    is ($as_perl->[1]->{subs}->[2]->{url}, 'resume.html', 'subs 1 url');
}

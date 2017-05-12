#!/usr/bin/perl -w

use strict;

use lib './t/lib';

use Test::More tests => 34;

use HTML::Widgets::NavMenu;

use HTML::Widgets::NavMenu::Test::Data;

my $test_data = get_test_data();

# This check tests that a leading path with a URL that is not registered
# in the nav menu still has one component of the root.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/non-existent-path/",
        @{$test_data->{'minimal'}},
    );

    my $rendered =
        $nav_menu->render();

    my @leading_path = @{$rendered->{'leading_path'}};

    # TEST
    ok ((scalar(@leading_path) == 1), "Checking for a leading path of len 1");

    my $component = $leading_path[0];

    # TEST
    is ($component->label(), "Home", "Testing for title of leading_path");

    # TEST
    is ($component->direct_url(), "../", "Testing for direct_url");
}

# This check tests the url_type behaviour of the leading-path
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/yowza/howza/",
        @{$test_data->{'rec_url_type_menu'}},
    );

    my $rendered =
        $nav_menu->render();

    my @leading_path = @{$rendered->{'leading_path'}};

    # TEST
    ok ((scalar(@leading_path) == 3), "Checking for a leading path of len 3");

    my $component = $leading_path[0];

    # TEST
    is ($component->label(), "Home", "Testing for title of leading_path");

    # TEST
    is ($component->direct_url(), "http://www.hello.com/~shlomif/",
        "Testing for direct_url");

    # TEST
    is ($component->url_type(), "full_abs", "Testing for url_type");

    $component = $leading_path[1];

    # TEST
    is ($component->label(), "Yowza", "Testing for label of leading_path");

    # TEST
    is ($component->direct_url(), "../",
        "Testing for direct_url");

    # TEST
    is ($component->url_type(), "rel", "Testing for url_type");

    $component = $leading_path[2];

    # TEST
    is ($component->label(), "This should be full_abs again",
        "Testing for label of leading_path");

    # TEST
    is ($component->direct_url(), "http://www.hello.com/~shlomif/yowza/howza/",
        "Testing for direct_url");

    # TEST
    is ($component->url_type(), "full_abs", "Testing for url_type");
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/sub-dir/",
        @{$test_data->{'url_is_abs_menu'}},
    );

    my $rendered =
        $nav_menu->render();

    my @leading_path = @{$rendered->{'leading_path'}};

    # TEST
    ok ((scalar(@leading_path) == 3), "Checking for a leading path of len 1");

    my $component = $leading_path[0];

    # TEST
    is ($component->label(), "Home", "Testing for title of leading_path");

    # TEST
    is ($component->direct_url(), "../", "Testing for direct_url");

    $component = $leading_path[1];

    # TEST
    is ($component->title(), "Google it!",
        "Testing for title of leading_path");

    # TEST
    is ($component->direct_url(), "http://www.google.com/",
        "Testing for direct_url");

    # TEST
    is ($component->url_type(), "full_abs", "Testing for url_type");

    $component = $leading_path[2];

    # TEST
    is ($component->direct_url(), "./",
        "Testing for direct_url");

    # TEST
    is ($component->url_type(), "rel", "Testing for url_type");
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/open-source/alohaware/",
        @{$test_data->{'selective_expand'}},
    );

    my $rendered =
        $nav_menu->render();

    my @leading_path = @{$rendered->{'leading_path'}};

    # TEST
    ok ((scalar(@leading_path) == 2), "Checking for a leading path of len 2");

    my $component = $leading_path[-1];

    # TEST
    is ($component->title(), "Open Source Software I Wrote",
        "Testing for title of leading_path");

    # TEST
    is ($component->direct_url(), "../",
        "Testing for direct_url");
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/puzzles/bar/",
        @{$test_data->{'root_path_not_slash'}},
    );

    my $rendered =
        $nav_menu->render();

    my @leading_path = @{$rendered->{'leading_path'}};

    # TEST
    is (scalar(@leading_path), 2, "Checking for a leading path of len 2");

    my $component = $leading_path[0];

    # TEST
    is ($component->label(), "Home",
        "Points to Home");

    # TEST
    is ($component->direct_url(), "../",
        "Testing for direct_url");
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/humour/by-others/foo.html",
        @{$test_data->{'non_capturing_expand'}},
    );

    my $rendered =
        $nav_menu->render();

    my @lp = @{$rendered->{'leading_path'}};

    # TEST
    is (scalar(@lp), 3, "Checking for a leading path of len 2");

    # TEST
    is ($lp[0]->direct_url(), "./../../", "lp[0]");

    # TEST
    is ($lp[1]->direct_url(), "./../", "lp[1]");

    # TEST
    is ($lp[2]->direct_url(), "./", "lp[2]");
}

# This test is to check that a non-capturing expand does not influence
# the upper capturing expands to not capture.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/humour/humanity/",
        @{$test_data->{'non_capturing_expand_nested'}},
    );

    my $rendered =
        $nav_menu->render();

    my @lp = @{$rendered->{'leading_path'}};

    # TEST
    is (scalar(@lp), 2, "Checking for a leading path of len 2");

    # TEST
    is ($lp[0]->direct_url(), "../../", "Pointing to the home");

    # TEST
    is ($lp[1]->direct_url(), "../", "Pointing to the humour");

}

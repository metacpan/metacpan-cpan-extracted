#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';

use Test::More tests => 15;

use HTML::Widgets::NavMenu;

use HTML::Widgets::NavMenu::Test::Data;

my $test_data = get_test_data();

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/resume.html",
        @{$test_data->{'with_skips'}},
    );

    # TEST
    is_deeply ($nav_menu->_get_current_coords(), [1, 2],
        "_get_current_coords()");

    # TEST
    is_deeply ($nav_menu->_get_next_coords(), [2],
        "Testing that _get_next_coords does _not_ skip skips by default");
    # TEST
    is_deeply ($nav_menu->_get_prev_coords(), [1,1],
        "Testing _get_prev_coords");

    # TEST
    is_deeply ($nav_menu->_get_up_coords(), [1],
        "Testing _get_up_coords()");
    # TEST
    is_deeply ($nav_menu->_get_up_coords([1, 2]), [1],
        "Testing _get_up_coords()");

    # TEST
    is_deeply ($nav_menu->_get_top_coords(), [0],
        "Testing _get_top_coords()");
    # TEST
    is_deeply ($nav_menu->_get_top_coords([1, 2]), [0],
        "Testing _get_top_coords()");

    # TEST
    is_deeply (
        $nav_menu->_get_coords_while_skipping_skips(
            \&HTML::Widgets::NavMenu::_get_next_coords
        ), [3],
        "Testing that skipping(_get_next_coords) does skip skips by default"
    );
    # TEST
    is_deeply (
        $nav_menu->_get_coords_while_skipping_skips(
            \&HTML::Widgets::NavMenu::_get_prev_coords
        ), [1,1],
        "Testing skipping(_get_prev_coords)"
    );

    # TEST
    is_deeply (
        $nav_menu->_get_coords_while_skipping_skips(
            \&HTML::Widgets::NavMenu::_get_next_coords,
            [1, 2]
        ), [3],
        "Testing that skipping(_get_next_coords) with explicit coords"
    );


}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/open-source/",
        @{$test_data->{'with_skips'}},
    );

    # TEST
    is_deeply ($nav_menu->_get_current_coords(), [3],
        "_get_current_coords()");

    # TEST
    is_deeply ($nav_menu->_get_next_coords(), [3,0],
        "Testing _get_next_coords");
    # TEST
    is_deeply ($nav_menu->_get_prev_coords(), [2],
        "Testing _get_prev_coords");

    # TEST
    is_deeply (
        $nav_menu->_get_coords_while_skipping_skips(
            \&HTML::Widgets::NavMenu::_get_next_coords
        ), [3, 1],
        "Testing that skipping(_get_next_coords) does skip skips by default"
    );
    # TEST
    is_deeply (
        $nav_menu->_get_coords_while_skipping_skips(
            \&HTML::Widgets::NavMenu::_get_prev_coords
        ), [1,2],
        "Testing skipping(_get_prev_coords)"
    );
}

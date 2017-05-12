#!/usr/bin/perl -w

use Test::More tests => 34;

use strict;

BEGIN {
use_ok ('HTML::Widgets::NavMenu::Tree::Node'); # TEST
}

{
    my $node = HTML::Widgets::NavMenu::Tree::Node->new();
    ok($node, "Constructing"); # TEST

    $node->url("Rabbi/Zalman/");
    is($node->url(), "Rabbi/Zalman/", "Testing for URL Setting"); # TEST
    $node->text("Trail of Innocence");
    is($node->text(), "Trail of Innocence", "Testing for text"); # TEST
    $node->show_always(1);
    is($node->show_always(), 1, "Set/get show_always"); # TEST
    $node->title("It's Raining");
    is($node->title(), "It's Raining", "Set/get title"); # TEST
    $node->host("vipe");
    is($node->host(), "vipe", "Set/get host"); # TEST
    $node->url_type("site_abs");
    is($node->url_type(), "site_abs", "Set/get url_type"); # TEST

    # Testing again for the same values to see that they are still OK.

    is($node->url(), "Rabbi/Zalman/", "Testing for URL Setting"); # TEST
    is($node->text(), "Trail of Innocence", "Testing for text"); # TEST
    is($node->show_always(), 1, "Set/get show_always");  # TEST
    is($node->title(), "It's Raining", "Set/get title"); # TEST
    is($node->host(), "vipe", "Set/get host"); # TEST
    is($node->url_type(), "site_abs", "Set/get url_type"); # TEST
}

{
    my $node = HTML::Widgets::NavMenu::Tree::Node->new();

    ok ((!$node->separator()), "Testing Node Separator - False"); # TEST
    $node->separator(1);
    ok ($node->separator(), "Testing Node Separator - True"); # TEST
}

{
    my $node = HTML::Widgets::NavMenu::Tree::Node->new();

    ok ((!$node->hide()), "Testing Node Hide - False"); # TEST
    $node->hide(1);
    ok ($node->hide(), "Testing Node Hide - True"); # TEST
}

{
    my $node = HTML::Widgets::NavMenu::Tree::Node->new();

    # TEST
    ok(!defined($node->role()),
        "Testing that role is undeffed at start");
    $node->role("hoola");
    is($node->role(), "hoola", "Testing role setted value"); # TEST
}

{
    my $node = HTML::Widgets::NavMenu::Tree::Node->new();

    ok((!$node->expanded()), "Testing node->expanded()"); # TEST
    $node->expand();
    ok($node->expanded(), "Testing node->expanded() after expand()"); # TEST
}

{
    my $node = HTML::Widgets::NavMenu::Tree::Node->new();

    ok((!$node->CurrentlyActive()), "Testing node->CurrentlyActive()"); # TEST
    # TEST
    ok((!$node->expanded()),
        "Testing node->expanded() before mark_as_current()");
    $node->mark_as_current();
    # TEST
    ok($node->CurrentlyActive(),
        "Testing node->CurAct() after mark_as_current()");
    # TEST
    ok($node->expanded(),
        "Testing node->expanded() after mark_as_current()");
}

{
    my $node = HTML::Widgets::NavMenu::Tree::Node->new();

    # TEST
    is(scalar(@{$node->subs()}), 0,
        "Testing emptiness of node->subs at start");

    my $sub_node1 = HTML::Widgets::NavMenu::Tree::Node->new();
    $sub_node1->url("Emperor/Kuzko/");
    $node->add_sub($sub_node1);
    # TEST
    is(scalar(@{$node->subs()}), 1, "node->subs len == 1");
    # TEST
    is($node->subs()->[0]->url(), "Emperor/Kuzko/", "node->subs contents");
    my $sub_node2 = HTML::Widgets::NavMenu::Tree::Node->new();
    $sub_node2->url("gimp/ressionist/");
    $node->add_sub($sub_node2);
    # TEST
    is(scalar(@{$node->subs()}), 2, "node->subs len == 2");
    # TEST
    is($node->subs()->[0]->url(), "Emperor/Kuzko/",
        "node->subs contents again");
    # TEST
    is($node->subs()->[1]->url(), "gimp/ressionist/",
        "node->subs[1] contents");
    # TEST
    ok(!$node->expanded(), "Node is not expanded");
    my $sub_node3 = HTML::Widgets::NavMenu::Tree::Node->new();
    $sub_node3->expand();
    $node->add_sub($sub_node3);
    # TEST
    ok($node->expanded(), "Node is expanded after adding an expanded item");
}


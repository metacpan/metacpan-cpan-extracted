#!/usr/bin/perl -w

use strict;

use Test::More tests => 9;

use HTML::Widgets::NavMenu;

{
my $text = "test/foo";

my $url = HTML::Widgets::NavMenu::_text_to_url_obj($text);

my $components = $url->_get_url();
ok (scalar(@$components) == 2); # TEST
ok ($components->[0] eq "test"); # TEST
ok ($components->[1] eq "foo"); # TEST
ok (! $url->_is_dir()); # TEST

}

{
    my $url1 = HTML::Widgets::NavMenu::Url->new(["links.html"], 0, "server");
    my $url2 = HTML::Widgets::NavMenu::Url->new(["links.html"], 0, "server");
    my $rel_url = $url1->_get_relative_url($url2, 0);
    ok ($rel_url eq "./links.html", "Checking for same file to itself link");  # TEST
}

{
    my $root_url = HTML::Widgets::NavMenu::Url->new("", 1);
    my $current_url = HTML::Widgets::NavMenu::Url->new("open-source/", 1);

    ok ($current_url->_get_relative_url($root_url, 1) eq "../",
        "Checking for link to root directory"); # TEST
}

{
    # TEST
    ok ((HTML::Widgets::NavMenu::_get_relative_url("open-source/", "") eq "../"),
        "_get_relative_url(): Checking for link to root directory"
    );
}

{
    eval {
    my $iter = HTML::Widgets::NavMenu::Iterator::Base->new();
    };

    # TEST
    like($@, qr{^nav_menu not specified},
        "nav_menu not specified");
}

{
    my $obj = HTML::Widgets::NavMenu::Object->new();

    # TEST
    isa_ok($obj, "HTML::Widgets::NavMenu::Object",
        "Testing creation of object");
}

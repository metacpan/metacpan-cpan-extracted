#!/usr/bin/perl -w

use strict;

use lib './t/lib';

use Test::More tests => 3;

use HTML::Widgets::NavMenu;

use HTML::Widgets::NavMenu::Test::Data;

my $test_data = get_test_data();

sub test_nav_menu
{
    my $rendered = shift;
    my $expected_string = shift;
    my $test_blurb = shift;

    my @result = (@{$rendered->{html}});

    my @expected = (split(/\n/, $expected_string));

    is_deeply (\@expected, \@result, $test_blurb);
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/",
        @{$test_data->{'two_sites'}},
    );

    my $rendered =
        $nav_menu->render();

    my $expected_string = <<"EOF";
<ul>
<li>
<a href="../">Home</a>
</li>
<li>
<b>About Me</b>
<br />
<ul>
<li>
<a href="../round/hello/personal.html" title="Biography of Myself">Bio</a>
</li>
<li>
<a href="../round/toto/" title="A Useful Conspiracy">Gloria</a>
</li>
</ul>
</li>
<li>
<a href="http://www.other-url.co.il/~shlomif/hoola/" title="Drumming is good for your health">Tam Tam Drums</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu($rendered, $expected_string, "Testing ul classes for no CSS class to be assigned.");
}

# This test tests the show_always directive which causes the entire
# sub-tree to expand at any URL.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/",
        @{$test_data->{'show_always'}},
        'ul_classes' => [ "FirstClass", "secondclass 2C", "ThirdClass" ],
    );

    my $rendered =
        $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="FirstClass">
<li>
<a href="../">Home</a>
</li>
<li>
<b>About Me</b>
</li>
<li>
<a href="../show-always/">Show Always</a>
<br />
<ul class="secondclass 2C">
<li>
<a href="../show-always/gandalf/">Gandalf</a>
</li>
<li>
<a href="../robin/">Robin</a>
<br />
<ul class="ThirdClass">
<li>
<a href="../robin/hood/">Hood</a>
</li>
</ul>
</li>
<li>
<a href="../esther/">Queen Esther</a>
<br />
<ul class="ThirdClass">
<li>
<a href="../haman/">Haman</a>
</li>
</ul>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu ($rendered, $expected_string, "Nav Menu with depth classes");
}

# This test tests the escaping of the class names.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/",
        @{$test_data->{'show_always'}},
        'ul_classes' => [ "F&F Class", "sec<h>", "T\"C" ],
    );

    my $rendered =
        $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="F&amp;F Class">
<li>
<a href="../">Home</a>
</li>
<li>
<b>About Me</b>
</li>
<li>
<a href="../show-always/">Show Always</a>
<br />
<ul class="sec&lt;h&gt;">
<li>
<a href="../show-always/gandalf/">Gandalf</a>
</li>
<li>
<a href="../robin/">Robin</a>
<br />
<ul class="T&quot;C">
<li>
<a href="../robin/hood/">Hood</a>
</li>
</ul>
</li>
<li>
<a href="../esther/">Queen Esther</a>
<br />
<ul class="T&quot;C">
<li>
<a href="../haman/">Haman</a>
</li>
</ul>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu ($rendered, $expected_string, "Nav Menu with depth classes");
}


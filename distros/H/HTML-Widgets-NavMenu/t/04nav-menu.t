#!/usr/bin/perl -w

use strict;

use lib './t/lib';

use Test::More tests => 30;

use HTML::Widgets::NavMenu                 ();
use HTML::Widgets::NavMenu::HeaderRole     ();
use HTML::Widgets::NavMenu::JQueryTreeView ();

use HTML::Widgets::NavMenu::Test::Data;

my $test_data = get_test_data();

sub test_nav_menu
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $rendered        = shift;
    my $expected_string = shift;
    my $test_blurb      = shift;

    my @result = ( @{ $rendered->{html} } );

    my @expected = ( split( /\n/, $expected_string ) );

    is_deeply( \@result, \@expected, $test_blurb );
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/hello/",
        @{ $test_data->{'minimal'} },
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="../">Home</a>
</li>
<li>
<a href="../me/" title="About Myself">About Me</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Nav Menu for minimal - 1" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/",
        @{ $test_data->{'two_sites'} },
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="../">Home</a>
</li>
<li>
<b>About Me</b>
<br />
<ul class="navbarnested">
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
    test_nav_menu( $rendered, $expected_string, "Nav Menu for minimal - 2" );
}

# This test tests that an expand_re directive should not cause
# the current coords to be assigned to it, thus marking a site
# incorrectly.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/",
        @{ $test_data->{'expand_re'} },
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="../">Home</a>
</li>
<li>
<b>About Me</b>
</li>
<li>
<a href="../foo/" title="Fooish">Foo</a>
<br />
<ul class="navbarnested">
<li>
<a href="../foo/expanded/" title="Expanded">Expanded</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Nav Menu for expand_re" );
}

# This test tests that an empty expand_re directive works after a successful
# pattern match.
{
    my $string = "aslkdjofisvniowgvnoaifnaoiwfb";
    $string =~ s{ofisvniowgvnoaifnaoiwfb$}{};
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/",
        @{ $test_data->{'expand_re'} },
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="../">Home</a>
</li>
<li>
<b>About Me</b>
</li>
<li>
<a href="../foo/" title="Fooish">Foo</a>
<br />
<ul class="navbarnested">
<li>
<a href="../foo/expanded/" title="Expanded">Expanded</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "Nav Menu for empty expand_re after successful pattern match" );
}

# This test tests the show_always directive which causes the entire
# sub-tree to expand at any URL.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/",
        @{ $test_data->{'show_always'} },
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="../">Home</a>
</li>
<li>
<b>About Me</b>
</li>
<li>
<a href="../show-always/">Show Always</a>
<br />
<ul class="navbarnested">
<li>
<a href="../show-always/gandalf/">Gandalf</a>
</li>
<li>
<a href="../robin/">Robin</a>
<br />
<ul class="navbarnested">
<li>
<a href="../robin/hood/">Hood</a>
</li>
</ul>
</li>
<li>
<a href="../esther/">Queen Esther</a>
<br />
<ul class="navbarnested">
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
    test_nav_menu( $rendered, $expected_string, "Nav Menu with show_always" );
}

# This test tests a menu auto-expands if the current URL is an item
# inside it.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/bio.html",
        @{ $test_data->{'items_in_sub'} },
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="./../">Home</a>
</li>
<li>
<a href="./" title="About Myself">About Me</a>
<br />
<ul class="navbarnested">
<li>
<b>Bio</b>
</li>
<li>
<a href="./gloria/" title="A Useful Conspiracy">Gloria</a>
</li>
</ul>
</li>
<li>
<a href="./../hoola/" title="Drumming is good for your health">Tam Tam Drums</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "Nav Menu with a selected sub-item" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/",
        @{ $test_data->{'separator'} },
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="../">Home</a>
</li>
<li>
<b>About Me</b>
<br />
<ul class="navbarnested">
<li>
<a href="group-hug/">Group Hug</a>
</li>
<li>
<a href="cool-io/">Cool I/O</a>
</li>
</ul>
<ul class="navbarnested">
<li>
<a href="../resume.html">Resume</a>
</li>
</ul>
</li>
</ul>
<ul class="navbarmain">
<li>
<a href="../halifax/">Halifax</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Nav Menu with Separators" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/",
        @{ $test_data->{'hidden_item'} },
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="../">Home</a>
</li>
<li>
<b>About Me</b>
<br />
<ul class="navbarnested">
<li>
<a href="visible/">Visible</a>
</li>
<li>
<a href="visible-too/">Visible Too</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Nav Menu with Hidden Item" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu::HeaderRole->new(
        'path_info' => "/good/",
        @{ $test_data->{'header_role'} },
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="../">Home</a>
</li>
</ul>
<h2>
<a href="../me/" title="About Myself">About Me</a>
</h2>
<ul class="navbarmain">
<li>
<a href="../me/sub-me1/">Sub Me</a>
</li>
<li>
<a href="../me/sub-me-two/">Sub Me 2</a>
</li>
<li>
<a href="../aloha/">Hello</a>
<br />
<ul class="navbarnested">
<li>
<a href="../aloha/obkb/">OBKB</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "Nav Menu with a role of \"header\"" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu::HeaderRole->new(
        'path_info' => "/me/",
        @{ $test_data->{'header_role'} },
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="../">Home</a>
</li>
</ul>
<h2>
<b>About Me</b>
</h2>
<ul class="navbarmain">
<li>
<a href="sub-me1/">Sub Me</a>
</li>
<li>
<a href="sub-me-two/">Sub Me 2</a>
</li>
<li>
<a href="../aloha/">Hello</a>
<br />
<ul class="navbarnested">
<li>
<a href="../aloha/obkb/">OBKB</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "Nav Menu with a selected item with a role of \"header\" " );
}

# Test the selective expand. (test #1)
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/bio/test.html",
        @{ $test_data->{'selective_expand'} },
        'ul_classes' => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="./../../">Home</a>
</li>
<li>
<a href="./../" title="About Myself">About Me</a>
<br />
<ul class="two">
<li>
<a href="./../group-hug/">Group Hug</a>
</li>
<li>
<a href="./../cool-io/">Cool I/O</a>
</li>
<li>
<a href="./../../resume.html">Resume</a>
</li>
</ul>
</li>
<li>
<a href="./../../halifax/">Halifax</a>
</li>
<li>
<a href="./../../open-source/" title="Open Source Software I Wrote">Software</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "Selective Expand Nav-Menu #1" );
}

# Test the selective expand. (test #2)
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/open-source/bits.html",
        @{ $test_data->{'selective_expand'} },
        'ul_classes' => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="./../">Home</a>
</li>
<li>
<a href="./../me/" title="About Myself">About Me</a>
</li>
<li>
<a href="./../halifax/">Halifax</a>
</li>
<li>
<a href="./" title="Open Source Software I Wrote">Software</a>
<br />
<ul class="two">
<li>
<a href="./fooware/">Fooware</a>
</li>
<li>
<a href="./condor-man/" title="Kwalitee">Condor-Man</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "Selective Expand Nav-Menu #2" );
}

# This is a test for the url_type directive.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/darling/",
        @{ $test_data->{'url_type_menu'} },
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul>
<li>
<a href="../">Home</a>
</li>
<li>
<a href="/me/" title="About Myself">About Me</a>
</li>
<li>
<a href="http://www.hello.com/yowza/">Yowza</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Nav Menu for url_type - 1" );
}

# This is a test for the rec_url_type directive.
# Also test the behaviour of the url_type when a trailing_url_base
# is specified
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/darling/",
        @{ $test_data->{'rec_url_type_menu'} },
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul>
<li>
<a href="http://www.hello.com/~shlomif/">Home</a>
</li>
<li>
<a href="/~shlomif/me/" title="About Myself">About Me</a>
</li>
<li>
<a href="http://www.hello.com/~shlomif/tedious/to/write/">Hoola</a>
</li>
<li>
<a href="../yowza/">Yowza</a>
<br />
<ul>
<li>
<a href="http://www.hello.com/~shlomif/yowza/howza/">This should be full_abs again</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "Nav Menu for rec_url_type - 1" );
}

# Test the url_is_abs directive
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/hello/",
        @{ $test_data->{'url_is_abs_menu'} },
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul>
<li>
<a href="../">Home</a>
</li>
<li>
<a href="http://www.google.com/" title="Google it!">Link to Google</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Nav Menu for url_is_asb - 1" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/bio/test.html",
        @{ $test_data->{'mixed_expand_menu'} },
        'current_host' => "default",
        'ul_classes'   => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="./../../">Home</a>
</li>
<li>
<a href="./../" title="About Myself">About Me</a>
<br />
<ul class="two">
<li>
<a href="./../group-hug/">Group Hug</a>
</li>
<li>
<a href="./../cool-io/">Cool I/O</a>
</li>
<li>
<a href="./../../resume.html">Resume</a>
</li>
</ul>
</li>
<li>
<a href="./../../halifax/">Halifax</a>
</li>
<li>
<a href="http://www.other.org/open-source/" title="Open Source Software I Wrote">Software</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Mixed Expand Nav-Menu #1" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/bio/test.html",
        @{ $test_data->{'mixed_expand_menu'} },
        'current_host' => "other",
        'ul_classes'   => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="http://www.default.net/">Home</a>
</li>
<li>
<a href="http://www.default.net/me/" title="About Myself">About Me</a>
</li>
<li>
<a href="http://www.default.net/halifax/">Halifax</a>
</li>
<li>
<a href="./../../open-source/" title="Open Source Software I Wrote">Software</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Mixed Expand Nav-Menu #2" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/open-source/not-exist/",
        @{ $test_data->{'mixed_expand_menu'} },
        'current_host' => "other",
        'ul_classes'   => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="http://www.default.net/">Home</a>
</li>
<li>
<a href="http://www.default.net/me/" title="About Myself">About Me</a>
</li>
<li>
<a href="http://www.default.net/halifax/">Halifax</a>
</li>
<li>
<a href="../" title="Open Source Software I Wrote">Software</a>
<br />
<ul class="two">
<li>
<a href="../fooware/">Fooware</a>
</li>
<li>
<a href="../condor-man/" title="Kwalitee">Condor-Man</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Mixed Expand Nav-Menu #3" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/base/",
        @{ $test_data->{'special_chars_menu'} },
        'current_host' => "default",
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul>
<li>
<a href="../">Home</a>
</li>
<li>
<a href="../&lt;hello&gt;&amp;&quot;you&quot;/">Special Chars</a>
</li>
<li>
<a href="../non-special/">Non-special</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Special Chars Nav Menu" );
}

# Test a special chars-based URL.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/<hello>&\"you\"/",
        @{ $test_data->{'special_chars_menu'} },
        'current_host' => "default",
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul>
<li>
<a href="../">Home</a>
</li>
<li>
<b>Special Chars</b>
</li>
<li>
<a href="../non-special/">Non-special</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "Nav Menu with a special chars URL." );
}

# Test a special chars-based URL.
{
    my %args = ( @{ $test_data->{'special_chars_menu'} } );
    delete( $args{'current_host'} );
    eval {
        my $nav_menu = HTML::Widgets::NavMenu->new(
            'path_info' => "/<hello>&\"you\"/",
            %args,
        );
    };

    # TEST
    like( $@, qr!^Current host!, "Checking for exception" );
}

# This is to test that the cb2 is working properly.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/not-exist/",
        @{ $test_data->{'mixed_expand_menu'} },
        'current_host' => "other",
        'ul_classes'   => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="http://www.default.net/">Home</a>
</li>
<li>
<a href="http://www.default.net/me/" title="About Myself">About Me</a>
</li>
<li>
<a href="http://www.default.net/halifax/">Halifax</a>
</li>
<li>
<a href="../../open-source/" title="Open Source Software I Wrote">Software</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Mixed Expand Nav-Menu #4" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/open-source/",
        @{ $test_data->{'mixed_expand_menu'} },
        'current_host' => "default",
        'ul_classes'   => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="../">Home</a>
</li>
<li>
<a href="../me/" title="About Myself">About Me</a>
</li>
<li>
<a href="../halifax/">Halifax</a>
</li>
<li>
<a href="http://www.other.org/open-source/" title="Open Source Software I Wrote">Software</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Mixed Expand Nav-Menu #5" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/humour/by-others/foo.html",
        @{ $test_data->{'non_capturing_expand'} },
        'current_host' => "default",
        'ul_classes'   => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="./../../">Home</a>
</li>
<li>
<a href="./../" title="My Humorous Creations">Humour</a>
<br />
<ul class="two">
<li>
<a href="./../stories/" title="Large-Scale Stories I Wrote">Stories</a>
<br />
<ul class="three">
<li>
<a href="./../TheEnemy/">The Enemy</a>
</li>
<li>
<a href="./../TOWTF/">TOW The Fountainhead</a>
</li>
</ul>
</li>
<li>
<a href="./">By Others</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string, "Non Capturing Expand" );
}

# This test tests that the URLs do not have "./" prepended to them
# when given the no_leading_dot option.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/bio.html",
        @{ $test_data->{'items_in_sub'} },
        'ul_classes'   => [ "navbarmain", ("navbarnested") x 5 ],
        no_leading_dot => 1,
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="../">Home</a>
</li>
<li>
<a href="./" title="About Myself">About Me</a>
<br />
<ul class="navbarnested">
<li>
<b>Bio</b>
</li>
<li>
<a href="gloria/" title="A Useful Conspiracy">Gloria</a>
</li>
</ul>
</li>
<li>
<a href="../hoola/" title="Drumming is good for your health">Tam Tam Drums</a>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "no_leading_dot removes the extra ./" );
}

{
    my $nav_menu = HTML::Widgets::NavMenu::HeaderRole->new(
        'path_info' => "/me/",
        @{ $test_data->{'header_role_with_empty_cat'} },
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="navbarmain">
<li>
<a href="../">Home</a>
</li>
</ul>
<h2>
<a href="../empty-cat/">Empty Category</a>
</h2>
<h2>
<b>About Me</b>
</h2>
<ul class="navbarmain">
<li>
<a href="sub-me1/">Sub Me</a>
</li>
<li>
<a href="sub-me-two/">Sub Me 2</a>
</li>
<li>
<a href="../aloha/">Hello</a>
<br />
<ul class="navbarnested">
<li>
<a href="../aloha/obkb/">OBKB</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "Nav Menu with an empty header role." );
}

# Test HTML::Widgets::NavMenu::JQueryTreeView .
{
    my $nav_menu = HTML::Widgets::NavMenu::JQueryTreeView->new(
        'path_info' => "/me/bio/test.html",
        @{ $test_data->{'selective_expand'} },
        'ul_classes' => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="./../../">Home</a>
</li>
<li class="open">
<a href="./../" title="About Myself">About Me</a>
<br />
<ul class="two">
<li>
<a href="./../group-hug/">Group Hug</a>
</li>
<li>
<a href="./../cool-io/">Cool I/O</a>
</li>
<li>
<a href="./../../resume.html">Resume</a>
</li>
</ul>
</li>
<li>
<a href="./../../halifax/">Halifax</a>
</li>
<li>
<a href="./../../open-source/" title="Open Source Software I Wrote">Software</a>
<br />
<ul class="two">
<li>
<a href="./../../open-source/fooware/">Fooware</a>
</li>
<li>
<a href="./../../open-source/condor-man/" title="Kwalitee">Condor-Man</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "HTML::Widgets::NavMenu::JQueryTreeView #1" );
}

# Test HTML::Widgets::NavMenu::JQueryTreeView with hidden.
{
    my $nav_menu = HTML::Widgets::NavMenu::JQueryTreeView->new(
        'path_info' => "/me/",
        @{ $test_data->{'hidden_item'} },
        'ul_classes' => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="../">Home</a>
</li>
<li class="open">
<b>About Me</b>
<br />
<ul class="two">
<li>
<a href="visible/">Visible</a>
</li>
<li>
<a href="visible-too/">Visible Too</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "JQTreeView Nav Menu with Hidden Item" );
}

# Test HTML::Widgets::NavMenu::JQueryTreeView with li_id.
{
    my $nav_menu = HTML::Widgets::NavMenu::JQueryTreeView->new(
        'path_info' => "/me/",
        @{ $test_data->{'with_ids_nav_menu'} },
        'ul_classes' => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="../">Home</a>
</li>
<li class="open" id="about_me">
<b>About Me</b>
<br />
<ul class="two">
<li id="visible">
<a href="visible/">Visible</a>
</li>
<li id="FooBar">
<a href="visible-too/">Visible Too</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "JQTreeView Nav Menu with li_id" );
}

# Test HTML::Widgets::NavMenu (non-JQueryTreeView) with li_id.
{
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/me/",
        @{ $test_data->{'with_ids_nav_menu'} },
        'ul_classes' => [ "one", "two", "three" ],
    );

    my $rendered = $nav_menu->render();

    my $expected_string = <<"EOF";
<ul class="one">
<li>
<a href="../">Home</a>
</li>
<li id="about_me">
<b>About Me</b>
<br />
<ul class="two">
<li id="visible">
<a href="visible/">Visible</a>
</li>
<li id="FooBar">
<a href="visible-too/">Visible Too</a>
</li>
</ul>
</li>
</ul>
EOF

    # TEST
    test_nav_menu( $rendered, $expected_string,
        "Non-JQTreeView Nav Menu with li_id" );
}

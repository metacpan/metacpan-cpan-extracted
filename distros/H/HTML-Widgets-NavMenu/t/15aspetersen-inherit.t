#!/usr/bin/perl

use strict;
use warnings;

package MyCustom::NavMenu::Iterator;

use parent 'HTML::Widgets::NavMenu::Iterator::NavMenu';

sub get_open_sub_menu_tags
{
    my $self = shift;
    return ( "<br class=\"hello\" />",
        $self->gen_ul_tag( { 'depth' => $self->stack->len() } ) );
}

sub get_currently_active_text
{
    my $self = shift;
    my $node = shift;
    return "<i class=\"shlomif\">" . $node->text() . "</i>";
}

1;

package MyCustom::NavMenu;

use parent 'HTML::Widgets::NavMenu';

sub _get_nav_menu_traverser
{
    my $self = shift;

    return MyCustom::NavMenu::Iterator->new(
        $self->_get_nav_menu_traverser_args() );
}

package main;

use lib './t/lib';

use Test::More tests => 1;

use HTML::Widgets::NavMenu ();

use HTML::Widgets::NavMenu::Test::Data;

my $test_data = get_test_data();

sub validate_nav_menu
{
    my $rendered        = shift;
    my $expected_string = shift;
    my $test_blurb      = shift;

    my @result = ( @{ $rendered->{html} } );

    my @expected = ( split( /\n/, $expected_string ) );

    is_deeply( \@expected, \@result, $test_blurb );
}

# This test tests that an inherited nav menu similar to what Stephen Petersen
# needs works.
{
    my $nav_menu = MyCustom::NavMenu->new(
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
<i class="shlomif">About Me</i>
</li>
<li>
<a href="../show-always/">Show Always</a>
<br class="hello" />
<ul class="navbarnested">
<li>
<a href="../show-always/gandalf/">Gandalf</a>
</li>
<li>
<a href="../robin/">Robin</a>
<br class="hello" />
<ul class="navbarnested">
<li>
<a href="../robin/hood/">Hood</a>
</li>
</ul>
</li>
<li>
<a href="../esther/">Queen Esther</a>
<br class="hello" />
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
    validate_nav_menu( $rendered, $expected_string,
        "Nav Menu with show_always" );
}


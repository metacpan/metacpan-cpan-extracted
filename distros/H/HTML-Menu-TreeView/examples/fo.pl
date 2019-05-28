#!/usr/bin/perl -w
use lib qw(lib);
use HTML::Menu::TreeView qw(Tree css jscript preload);
use CGI qw(-compile :all  -private_tempfiles);
use strict;
my @tree = (
    {
        onclick => "alert('onclick');",
        text    => 'onclick',
    },
    {
        text    => 'Html::Menu::TreeView',
        target  => '_parent',
        subtree => [
            {
                text    => 'Examples',
                subtree => [
                    {
                        text => 'OO Syntax',
                        href => './oo.pl',
                    },
                ],
            },
        ],
    },
    {
        ondblclick => "alert('ondblclick');",
        text       => 'ondblclick',
        title      => 'ondblclick',
    },
);
print(
    header(),
    start_html(
        -title  => 'Fo',
        -script => jscript() . preload(),
        -style  => { -code => css() }
    ),
    Tree( \@tree ),
    end_html
);

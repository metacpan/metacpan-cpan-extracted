#!/usr/bin/perl

use strict;
use warnings;

use HTML::Widgets::NavMenu;
use File::Path;

my $css_style = <<"EOF";
a:hover { background-color : palegreen; }
.body {
    float : left;
    width : 70%;
    padding-bottom : 1em;
    padding-top : 0em;
    margin-left : 1em;
    background-color : white

}
.navbar {
    float : left;
    background-color : moccasin;
    width : 20%;
    border-color : black;
    border-width : thick;
    border-style : double;
    padding-left : 0.5em;
}
.navbar ul
{
    font-family: sans-serif;
    font-size : small;
    margin-left : 0.3em;
    padding-left : 1em;
}
EOF

my $nav_menu_tree = {
    'host'  => "default",
    'text'  => "Top 1",
    'title' => "T1 Title",
    'subs'  => [
        {
            'text' => "Home",
            'url'  => "",
        },
        {
            'text'  => "About Me",
            'title' => "About Myself",
            'url'   => "me/",
        },
        {
            'text'  => "Links",
            'title' => "Hyperlinks to other Pages",
            'url'   => "links/",
        },
    ],
};

my %hosts = (
    'hosts' => {
        'default' => {
            'base_url' => (
                      "http://web-cpan.berlios.de/modules/"
                    . "HTML-Widgets-NavMenu/article/examples/simple/dest/"
            ),
        },
    },
);

my @pages = (
    {
        'path'    => "",
        'title'   => "John Doe's Homepage",
        'content' => <<'EOF',
<p>
Hi! This is the homepage of John Doe. I hope you enjoy your stay here.
</p>
EOF
    },
    {
        'path'    => "me/",
        'title'   => "About Myself",
        'content' => <<'EOF',
<p>
My name is John Doe and I've been exploring the art and science of creating
navigation menus for 10 years now. I find navigation menus to be a fascinating
subject, and think everyone should be interested in them.
</p>
EOF
    },
    {
        'path'    => "links/",
        'title'   => "Cool Links",
        'content' => <<'EOF',
<h2>Perl-Related Links</h2>

<ul>
<li>
<a href="http://www.perl.com/">Perl.com - a site with Perl articles</a>.
</li>
<li>
<a href="http://www.perl.org/">Perl.org</a> - the homepage of the Perl
community.
</li>
<li>
<a href="http://perl-begin.berlios.de/">Perl Beginners' Site</a>
</li>
</ul>
EOF
    },
);

foreach my $page (@pages)
{
    my $path     = $page->{'path'};
    my $title    = $page->{'title'};
    my $content  = $page->{'content'};
    my $nav_menu = HTML::Widgets::NavMenu->new(
        path_info     => "/$path",
        current_host  => "default",
        hosts         => \%hosts,
        tree_contents => $nav_menu_tree,
    );

    my $nav_menu_results = $nav_menu->render();

    my $nav_menu_text = join( "\n", @{ $nav_menu_results->{'html'} } );

    my $file_path = $path;
    if ( ( $file_path =~ m{/$} ) || ( $file_path eq "" ) )
    {
        $file_path .= "index.html";
    }
    my $full_path = "dest/$file_path";
    $full_path =~ m{^(.*)/[^/]+$};

    # mkpath() throws an exception if it isn't successful, which will cause
    # this program to terminate. This is what we want.
    mkpath( $1, 0, 0755 );
    open my $out, ">", $full_path
        or die "Could not open \"$full_path\" for writing!";

    print {$out} <<"EOF";
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
<title>$title</title>
<style type="text/css">
$css_style
</style>
</head>
<body>
<div class="navbar">
$nav_menu_text
</div>
<div class="body">
<h1>$title</h1>
$content
</div>
</body>
</html>
EOF

    close($out);
}


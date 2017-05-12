#!/usr/bin/perl

use strict;
use warnings;

use HTML::Widgets::NavMenu;
use HTML::Latemp::NavLinks::GenHtml::ArrowImages;

my $css_style = <<"EOF";
a:hover { background-color : palegreen; }
.body {
    float : left;
    width : 70%;
    padding-bottom : 1em;
    padding-top : 0em;
    margin-left : 1em;
    background-color : white;

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
.navlinks
{
   background-color:
#30C020;
  margin-bottom : 0.2em;
  padding-left: 0.5em;
  padding-bottom: 0.2em;
  border-style: solid;
  border-width: thin;
  border-color:  black;
}
.breadcrumb
{
    background-color: #4190e1;
    padding-bottom: 0.3em;
    padding-left: 0.5em;
    padding-top: 0.3em;
    margin-bottom: 0.2em;
    border-style: solid;
    border-width: thin;
    border-color: #FF8080;
    font-size: 80%;
}

.breadcrumb :link
{
   color: #FFFF00 ;
}

.breadcrumb :link:hover
{
   color: red;
}

.breadcrumb :visited
{
    color: #F5F5DC;
}

.breadcrumb :visited:hover
{
    color: #800000;
}
EOF

my $nav_menu_tree =
{
    'host' => "default",
    'text' => "HTML-Widgets-NavMenu Example",
    'title' => "HTML-Widgets-NavMenu",
    'subs' =>
    [
        {
            'text' => "Home",
            'url' => "",
        },
        {
            'text' => "About Myself",
            'url' => "me/",
            'subs' =>
            [
                {
                    'text' => "Bio",
                    'url' => "personal.html",
                    'title' => "A Short Biography of Myself",
                },
                {
                    'text' => "Contact",
                    'url' => "me/contact-me/",
                    'title'=> "How to Contact me in Every Conceivable Way",
                },
                {
                    'text' => "My Resum&eacute;s",
                    'url' => "me/resumes/",
                    'subs' =>
                    [
                        {
                            'text' => "English Resum&eacute;",
                            'url' => "resume.html",
                        },
                        {
                            'text' => "Detailed English Resum&eacute;",
                            'url' => "resume_detailed.html",
                        },
                    ],
                },
            ],
        },
        {
            'text' => "Humour",
            'url' => "humour/",
            'title' => "My Humorous Creations",
            'subs' =>
            [
                {
                    'text' => "The Enemy",
                    'url' => "humour/TheEnemy/",
                    'title' => "The Enemy and How I Helped to Fight It",
                },
                {
                    'text' => "TOWTF",
                    'url' => "humour/TOWTF/",
                    'title' => "The One with the Fountainhead",
                },
                {
                    'text' => "The Pope",
                    'url' => "humour/Pope/",
                    'title' => "The Pope Died on Sunday",
                },
                {
                    'text' => "Humour Archive",
                    'title' => "Archive of Humorous Bits I came up with",
                    'url' => "humour.html",
                },
                {
                    'text' => "Fortune Cookies Collection",
                    'title' => "Collection of Files for Input to the UNIX 'fortune' Program",
                    'url' => "humour/fortunes/",
                },
            ],
        },
        {
            'text' => "Math-Ventures",
            'url' => "MathVentures/",
            'title' => "Mathematical Riddles and their Solutions",
        },
        {
            'text' => "Computer Art",
            'url' => "art/",
            'title' => "Computer art I created while explaining how.",
            'subs' =>
            [
                {
                    'text' => "Back to my Homepage",
                    'url' => "art/bk2hp/",
                    'title' => "A Back to my Homepage logo not unlike the one from the movie &quot;Back to the Future&quot;",
                },
                {
                    'text' => "Linux Banner",
                    'url' => "art/linux_banner/",
                    'title' => "Linux - Because Software Problems should not Cost Money",
                },
            ],
        },
        {
            'text' => "Software",
            'url' => "open-source/",
            'title' => "Pages related to Software (mostly Open-Source)",
            'subs' =>
            [
                {
                    'text' => "Freecell Solver",
                    'url' => "open-source/projects/freecell-solver/",
                },
                {
                    'text' => "MikMod for Java",
                    'title' => "A Player for MOD Files (a type of Music Files) for the Java Environment",
                    'url' => "jmikmod/",
                },
                {
                    'text' => "FCFS RWLock",
                    'title' => "A First-Come First-Served Readers/Writers Lock",
                    'url' => "rwlock/",
                },
                {
                    'text' => "Quad-Pres",
                    'title' => "A Tool for Creating HTML Presentations",
                    'url' => "open-source/projects/quad-pres/",
                },
                {
                    'text' => "Favourite OSS",
                    'title' => "Favourite Open-Source Software",
                    'url' => "open-source/favourite/",
                },
                {
                    'text' => "Interviews",
                    'title' => "Interviews with Open-Source People",
                    'url' => "open-source/interviews/",
                },
                {
                    'text' => "Contributions",
                    'title' => "Contributions to Other Projects, that I did not Start",
                    'url' => "open-source/contributions/",
                },
                {
                    'text' => "Bits and Bobs",
                    'title' => "Various Small-Scale Open-Source Works",
                    'url' => "open-source/bits.html",
                },
                {
                    'text' => "Portability Libraries",
                    'title' => "Cross-Platform Abstraction Libraries",
                    'url' => "abstraction/",
                },
                {
                    'text' => "Software Tools",
                    'title' => "Software Construction and Management Tools",
                    'url' => "software-tools/",
                },
            ],
        },
        {
            'text' => "Lectures",
            'url' => "lecture/",
            'title' => "Presentations I Wrote (Mostly Technical)",
            'subs' =>
            [
                {
                    'text' => "Perl for Newbies",
                    'url' => "lecture/Perl/Newbies/",
                },
                {
                    'text' => "Freecell Solver",
                    'url' => "lecture/Freecell-Solver/",
                },
                {
                    'text' => "Lambda Calculus",
                    'title' => "A presentation about a Turing-complete programming environment with only two primitives",
                    'url' => "lecture/lc/",
                },
                {
                    'text' => "The Gimp",
                    'title' => "A Presentation about the GNU Image Manipulation Program",
                    'url' => "lecture/Gimp/",
                },
                {
                    'text' => "GNU Autotools",
                    'url' => "lecture/Autotools/",
                },
                {
                    'text' => "Web Meta Lecture",
                    'title' => "A Presentation about the Web Meta Language",
                    'url' => "lecture/WebMetaLecture/",
                },
            ],
        },
        {
            'text' => "Essays",
            'url' => "essays/",
            'title' => "Various Essays and Articles about Technology and Philosophy in General",
            'subs' =>
            [
                {
                    'text' => "Index to Essays",
                    'url' => "essays/Index/",
                    'title' => "Index to Essays and Articles I wrote.",
                },
                {
                    'text' => "Open Source",
                    'url' => "essays/open-source/",
                    'title' => "Essays about Open-Source",
                },
                {
                    'text' => "Life",
                    'url' => "essays/life/",
                    'title' => "Essays about Life, the Universe and Everything",
                },
            ],
        },
        {
            'text' => "Cool Links",
            'url' => "links.html",
            'title' => "An incomplete list of links I find cool and/or useful.",
        },
        {
            'text' => "Site Map",
            'url' => "site-map/",
            'title' => "A site map for the site with all the pages",
        },

    ],
};

my %hosts =
(
    'hosts' =>
    {
        'default' =>
        {
            'base_url' => ("http://web-cpan.berlios.de/modules/" .
                "HTML-Widgets-NavMenu/article/examples/simple/dest/"),
        },
    },
);

my @page_paths =
("", "me/", "personal.html", "me/contact-me/", "me/resumes/", "resume.html",
"resume_detailed.html", "humour/", "humour/TheEnemy/", "humour/TOWTF/",
"humour/Pope/", "humour.html", "humour/fortunes/", "MathVentures/",
"art/", "art/bk2hp/", "art/linux_banner/", "open-source/",
"open-source/projects/freecell-solver/", "jmikmod/", "rwlock/",
"open-source/projects/quad-pres/", "open-source/favourite/",
"open-source/interviews/", "open-source/contributions/",
"open-source/bits.html", "abstraction/", "software-tools/", "lecture/",
"lecture/Perl/Newbies/", "lecture/Freecell-Solver/", "lecture/lc/",
"lecture/Gimp/", "lecture/Autotools/", "lecture/WebMetaLecture/",
"essays/", "essays/Index/", "essays/open-source/", "essays/life/",
"links.html");

my @pages =
    (map {
        +{ 'path' => $_, 'title' => "Title for $_",
        'content' => "<p>Content for $_</p>" }
    } @page_paths);

# Add the site-map page.
{
    my $site_map_path = "site-map/";
    my $site_map_generator =
        HTML::Widgets::NavMenu->new(
            path_info => "/$site_map_path",
            current_host => "default",
            hosts => \%hosts,
            tree_contents => $nav_menu_tree
        );
    push @pages,
    {
        'path' => $site_map_path,
        'title' => "Site Map",
        'content' => join("\n", @{$site_map_generator->gen_site_map()}),
    };
};

foreach my $page (@pages)
{
    my $path = $page->{'path'};
    my $nav_menu =
        HTML::Widgets::NavMenu->new(
            path_info => "/$path",
            current_host => "default",
            hosts => \%hosts,
            tree_contents => $nav_menu_tree,
        );

    my $nav_menu_results = $nav_menu->render();

    my $gen_links_html =
        HTML::Latemp::NavLinks::GenHtml::ArrowImages->new(
            'root' => $nav_menu->get_cross_host_rel_url(
                host => "default",
                host_url => "",
                url_type => "rel",
                url_is_abs => 0,
            ),
            'nav_links_obj' => $nav_menu_results->{'nav_links_obj'},
        );

    print "Nav Links for Page \"$path\":\n<<<<<<<<<<\n",
        $gen_links_html->get_total_html(),
        "\n>>>>>>>>>>>>>\n\n\n";
}


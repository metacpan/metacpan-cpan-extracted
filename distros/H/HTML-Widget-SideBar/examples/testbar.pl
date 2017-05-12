#! /usr/bin/perl -wT

use strict;
use version '0.05';

use CGI qw(:standard);
use HTML::Widget::SideBar;

my $tree = HTML::Widget::SideBar->new(value => 'sidebar');
$tree->setToggleAction;

foreach (1..3) {
    my $list = $tree->append(value => "list$_");
    $list->append(value => "aaa$_", URL => "http://localhost/$_");
    $list->append(value => "bbb$_");
    $list->append(value => "ccc$_");
}
$tree->getSubTree(3)->setActive;

# Try this one instead of what's below.
my $style = "
#sidebar {
     position: absolute;
     top: 0px;
     left: 0px;
     height: 100%;
     width: 20%;
     background: yellow;
}

#content {
    margin-left: 20%;
}

.item {
    color: black;
}

.itemActive {
    font-weight: bold;
}";

print header, start_html(-style => $tree->buildCSS($tree->deepBlueCSS), 
-script => $tree->baseJS);
print join "\n", $tree->getHTML(styles => {bar => 'nav',
					  level0 => 'navlink',
					  level0Over => 'navover'},
				expand => 1
			       );
print end_html;

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/HTML/Widgets/NavMenu.pm',
    'lib/HTML/Widgets/NavMenu/EscapeHtml.pm',
    'lib/HTML/Widgets/NavMenu/ExpandVal.pm',
    'lib/HTML/Widgets/NavMenu/HeaderRole.pm',
    'lib/HTML/Widgets/NavMenu/Iterator/Base.pm',
    'lib/HTML/Widgets/NavMenu/Iterator/Html.pm',
    'lib/HTML/Widgets/NavMenu/Iterator/Html/Item.pm',
    'lib/HTML/Widgets/NavMenu/Iterator/JQTreeView.pm',
    'lib/HTML/Widgets/NavMenu/Iterator/NavMenu.pm',
    'lib/HTML/Widgets/NavMenu/Iterator/NavMenu/HeaderRole.pm',
    'lib/HTML/Widgets/NavMenu/Iterator/SiteMap.pm',
    'lib/HTML/Widgets/NavMenu/JQueryTreeView.pm',
    'lib/HTML/Widgets/NavMenu/Object.pm',
    'lib/HTML/Widgets/NavMenu/Predicate.pm',
    'lib/HTML/Widgets/NavMenu/TagGen.pm',
    'lib/HTML/Widgets/NavMenu/Tree/Iterator.pm',
    'lib/HTML/Widgets/NavMenu/Tree/Iterator/Item.pm',
    'lib/HTML/Widgets/NavMenu/Tree/Iterator/Stack.pm',
    'lib/HTML/Widgets/NavMenu/Tree/Node.pm',
    'lib/HTML/Widgets/NavMenu/Url.pm',
    't/00-compile.t',
    't/00use.t',
    't/01unit.t',
    't/02site-map.t',
    't/03nav-links.t',
    't/04nav-menu.t',
    't/05stack.t',
    't/06tree-iter-item.t',
    't/07tree-iter.t',
    't/08tree-node.t',
    't/09leading-path.t',
    't/10ul-classes.t',
    't/11predicate.t',
    't/12x-host-rel-url.t',
    't/13escape-html.t',
    't/14tag-gen.t',
    't/15aspetersen-inherit.t',
    't/16redirect.t',
    't/17nav-coords-unit.t',
    't/18url.t',
    't/lib/HTML/Widgets/NavMenu/Test/Data.pm',
    't/lib/HTML/Widgets/NavMenu/Test/Stdout.pm',
    't/lib/HTML/Widgets/NavMenu/Test/Util.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

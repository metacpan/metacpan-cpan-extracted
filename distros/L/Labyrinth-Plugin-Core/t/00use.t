#!/usr/bin/perl -w
use strict;

use Test::More tests => 14;

BEGIN {
    use_ok('Labyrinth::Plugin::Articles');
    use_ok('Labyrinth::Plugin::Articles::Sections');
    use_ok('Labyrinth::Plugin::Articles::Site');
    use_ok('Labyrinth::Plugin::Content');
    use_ok('Labyrinth::Plugin::Core');
    use_ok('Labyrinth::Plugin::Folders');
    use_ok('Labyrinth::Plugin::Groups');
    use_ok('Labyrinth::Plugin::Hits');
    use_ok('Labyrinth::Plugin::Images');
    use_ok('Labyrinth::Plugin::Inbox');
    use_ok('Labyrinth::Plugin::Menus');
    use_ok('Labyrinth::Plugin::News');
    use_ok('Labyrinth::Plugin::Users');
    use_ok('Labyrinth::Plugin::Users::Info');
}

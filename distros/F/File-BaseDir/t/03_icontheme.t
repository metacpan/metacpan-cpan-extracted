#!perl
use strict;
use warnings FATAL   => 'all';
use Test::More;
use Config;
use File::IconTheme qw(xdg_icon_theme_search_dirs);
require File::Spec;
use File::Temp qw();

if ($^O eq 'MSWin32') {
    plan skip_all => 'File path comparisons cannot be made on MS Windows operating system.';
}
else {
    plan tests => 1;
}

my @dirs = map {File::Temp->newdir} 0 .. 2;
my @icondirs = map {File::Spec->catfile($_, 'icons')} @dirs;
mkdir $_ for @icondirs;

$ENV{XDG_DATA_HOME} = $dirs[0];
$ENV{XDG_DATA_DIRS} = $dirs[1] . $Config{path_sep} . $dirs[2];

is_deeply
    [xdg_icon_theme_search_dirs],
    [grep {-d $_ && -r $_}
        File::Spec->catfile($ENV{HOME}, '.icons'),
        @icondirs,
        '/usr/share/pixmaps'
    ];
    

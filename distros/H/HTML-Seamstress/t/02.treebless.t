# This might look like shell script, but it's actually -*- perl -*-
use strict;
use lib qw(t/ t/m/);


use File::Slurp;
package tree::bless;

use Test::More qw(no_plan);
use TestUtils;

use base qw(HTML::Seamstress) ;


my $root = 't/html/treebless';

my $tree = __PACKAGE__->new_from_file("$root.html");

my $li = $tree->look_down(class => 'greg');

warn $li->as_HTML;

is (ref $li, 'tree::bless', 'blessed into proper class');

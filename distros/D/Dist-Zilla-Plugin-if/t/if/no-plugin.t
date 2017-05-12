
use strict;
use warnings;

use Test::More tests => 1;

# ABSTRACT: A basic test

use Test::DZil qw( simple_ini Builder);

my $files = { 'source/dist.ini' => simple_ini( [ 'if' => {} ] ) };
my $zilla;

isnt( eval { $zilla = Builder->from_config( { dist_root => 'invalid' }, { add_files => $files } ); 1 },
  1, "Configure fails without plugin" );

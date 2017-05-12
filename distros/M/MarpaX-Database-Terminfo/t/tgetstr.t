#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 13;
use File::Spec;
use Path::Tiny qw/path/;

my $path;

BEGIN { $path = path(File::Spec->curdir)->absolute->stringify;
        $path =~ /(.*)/;
        $path = $1;
}

use Test::File::ShareDir
    -root  =>  $path,
    -share =>  {
        -module => { 'MarpaX::Database::Terminfo' => File::Spec->curdir },
        -dist => { 'MarpaX-Database-Terminfo' => File::Spec->curdir },
};
#------------------------------------------------------
BEGIN {
    use_ok( 'MarpaX::Database::Terminfo::Interface', qw/:functions/ ) || print "Bail out!\n";
}
my $t = MarpaX::Database::Terminfo::Interface->new();
$t->tgetent('dumb');
my $area;
is(ref($t->tgetstr('bl')), 'SCALAR', "\$t->tgetstr('bl') returns a reference to a scalar");
is(${$t->tgetstr('bl', \$area)}, '^G', "\$t->tgetstr('bl') deferenced scalar");
is($area, '^G', "\$t->tgetstr('bl', \\\$area) where \\\$area is undef");
is(pos($area), 2, "pos(\\\$area) == 2");
$area = 'x';
pos($area) = length($area);
is(ref($t->tgetstr('bl')), 'SCALAR', "\$t->tgetstr('bl')");
is(${$t->tgetstr('bl', \$area)}, '^G', "\$t->tgetstr('bl')");
is($area, 'x^G', "\$t->tgetstr('bl', \\\$area) where \\\$area is \"x\" and its pos() is 1");
is(pos($area), 3, "pos(\\\$area) == 3");
$area = 'x';
pos($area) = undef;
is(ref($t->tgetstr('bl')), 'SCALAR', "\$t->tgetstr('bl')");
is(${$t->tgetstr('bl', \$area)}, '^G', "\$t->tgetstr('bl')");
is($area, '^Gx', "\$t->tgetstr('bl', \\\$area) where \\\$area is \"x\" and its pos() is undef");
is(pos($area), 2, "pos(\\\$area) == 2");

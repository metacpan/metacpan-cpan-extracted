#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 11;
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
is($t->tvgetstr('notexisting', \$area), 0, "\$t->tvgetstr('notexisting', \\\$area) returns false");
is($t->tvgetstr('bell', \$area), 1, "\$t->tvgetstr('bell', \\\$area) returns true");
is($area, '^G', "\$area value");
is(pos($area), 2, "pos(\\\$area) == 2");
$area = 'x';
pos($area) = length($area);
is($t->tvgetstr('bell', \$area), 1, "\$t->tvgetstr('bell', \\\$area) returns true");
is($area, 'x^G', "\$area value where \\\$area was \"x\" and pos() 1");
is(pos($area), 3, "pos(\\\$area) == 3");
$area = 'x';
pos($area) = undef;
is($t->tvgetstr('bell', \$area), 1, "\$t->tvgetstr('bell', \\\$area) returns true");
is($area, '^Gx', "\$area value where \\\$area was \"x\" and pos() undef");
is(pos($area), 2, "pos(\\\$area) == 2");

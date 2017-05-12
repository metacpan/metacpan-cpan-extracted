#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 5;
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
my $t = MarpaX::Database::Terminfo::Interface->new({use_env => 0});
$t->tgetent('dumb');
my $columns = undef;
is($t->tvgetnum('notexisting', \$columns), 0, "\$t->tvgetnum('notexisting', \\\$columns) returns false");
is($columns, undef, "\$columns value untouched");
is($t->tvgetnum('columns', \$columns), 1, "\$t->tvgetnum('columns', \\\$columns) returns true");
is($columns, 80, "\$columns value is 80");

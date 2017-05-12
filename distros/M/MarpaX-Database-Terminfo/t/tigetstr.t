#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 6;
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
    use_ok( 'MarpaX::Database::Terminfo::Interface', qw/:all/ ) || print "Bail out!\n";
}
my $t = MarpaX::Database::Terminfo::Interface->new();
$t->tgetent('nsterm-16color');
is(ref($t->tigetstr('fsl')), 'SCALAR', "\$t->tigetstr('fsl') returns a reference to a SCALAR");
is(${$t->tigetstr('fsl')}, '^G', "\$t->tigetstr('fsl') - string value");
is($t->tigetstr('wsl'), -1, "\$t->tigetstr('zsl') - not a string capability");
is($t->tigetstr('absentcap'), 0, "\$t->tigetstr('absentcap') - absent capability ");
is($t->tigetstr('bw'), 0, "\$t->tigetflag('bw') - cancelled capability");

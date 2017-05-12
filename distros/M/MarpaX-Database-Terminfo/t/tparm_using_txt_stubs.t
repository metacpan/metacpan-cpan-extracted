#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
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
    $ENV{MARPAX_DATABASE_TERMINFO_STUBS_TXT} = File::Spec->catfile('share', 'ncurses-terminfo-stubs.txt');
}
my $t = MarpaX::Database::Terminfo::Interface->new();
$t->tgetent('ibcs2');
#
# cup is the cursor adress
#
my $cupp = $t->tigetstr('cup'); # \E[%i%p1%d;%p2%dH
is ($t->tparm(${$cupp}, 18, 40), "\e[19;41H", "ibcs2 cursor_adress '${$cupp}' with parameters (18, 40)");

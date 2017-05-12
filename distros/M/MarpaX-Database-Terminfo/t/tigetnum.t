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
    use_ok( 'MarpaX::Database::Terminfo::Interface', qw/:all/ ) || print "Bail out!\n";
}
my $t = MarpaX::Database::Terminfo::Interface->new({use_env => 0});
$t->tgetent('nsterm-16color');
is($t->tigetnum('wsl'), 50, "\$t->tigetnum('wsl') - numeric value");
is($t->tigetnum('fsl'), -2, "\$t->tigetnum('fsl') - not a numeric capability");
is($t->tigetnum('absentcap'), -1, "\$t->tigetnum('absentcap') - absent capability ");
is($t->tigetnum('bw'), -1, "\$t->tigetflag('bw') - cancelled capability");

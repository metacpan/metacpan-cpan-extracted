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
my $t = MarpaX::Database::Terminfo::Interface->new();
$t->tgetent('nsterm-16color');
is($t->tigetflag('am'), 1, "\$t->tigetflag('am') - boolean value");
is($t->tigetflag('cols'), -1, "\$t->tigetflag('cols') - not a boolean capability");
is($t->tigetflag('absentcap'), 0, "\$t->tigetflag('absentcap') - absent capability ");
is($t->tigetflag('bw'), 0, "\$t->tigetflag('bw') - cancelled capability");

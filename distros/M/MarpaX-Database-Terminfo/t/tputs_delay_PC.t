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
    $ENV{MARPAX_DATABASE_TERMINFO_OSPEED} = 13;
    use_ok( 'MarpaX::Database::Terminfo::Interface', qw/:all/ ) || print "Bail out!\n";
}
my $t = MarpaX::Database::Terminfo::Interface->new();
$t->tgetent('dm2500');
#
# cup is the cursor adress
#
my $cupp = $t->tigetstr('cup'); # \014%p2%{96}%^%c%p1%{96}%^%c
my $got = '';
my $wanted = chr(oct(14)) . chr(72) . chr(114) . chr(255) . chr(0);
#
# Untaint data
#
my $input = ${$cupp} . '$<1>';
my ($untainted) = $input =~ m/(.*)/s;
$t->tputs($t->tgoto($untainted, 40, 18), 1, \&outc);
is($got, $wanted, 'cup at 18:40 under terminal dm2500 that have pad_char');

sub outc {
    my ($c) = @_;
    if ($c) {
        $got .= $c;
    } else {
        $got .= chr(0);
    }
}

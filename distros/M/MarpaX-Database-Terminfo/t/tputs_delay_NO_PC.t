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
}
my $t = MarpaX::Database::Terminfo::Interface->new();
$t->tgetent('ibcs2');
#
# cup is the cursor adress
#
my $cupp = $t->tigetstr('cup'); # \E[%i%p1%d;%p2%dH
my $got = '';
my $wanted = "\e" . chr(91) . chr(49) . chr(57) . chr(59) . chr(52) . chr(49) . chr(72) . chr(0);
#
# Untaint data
#
my $input = ${$cupp} . '$<1000>';
my ($untainted) = $input =~ m/(.*)/s;
$t->tputs($t->tgoto($untainted, 40, 18), 1, \&outc);
is($got, $wanted, 'cup at 18:40 under terminal ibcs2 that have no pad_char');

sub outc {
    my ($c) = @_;
    if ($c) {
        $got .= $c;
    } else {
        $got .= chr(0);
    }
}

#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;
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
my $number_of_tests_run = 1;
BEGIN {
    use_ok( 'MarpaX::Database::Terminfo::Interface', qw/:all/ ) || print "Bail out!\n";
}
#
# Test all terminals in the ncurses database
#
my $t = MarpaX::Database::Terminfo::Interface->new();
my %alias = ();
foreach (@{$t->_terminfo_db}) {
    foreach (@{$_->{alias}}) {
        ++$alias{$_};
    }
}
foreach (sort keys %alias) {
    ++$number_of_tests_run;
    is($t->tgetent($_), 1, "\$t->tgetent('$_')");
}
done_testing( $number_of_tests_run );

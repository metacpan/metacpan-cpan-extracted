#!/usr/bin/perl

use strict;
use warnings;

use Test::More ( tests => 3 );
use IO::File;

use Devel::Walk::Unstorable;

############################################
my $fh = IO::File->new;
my $honk;
my $top = {
        array => [ 0..2, { honk=>'bonk'}, 0, \{ arraywithhash => [10,{unclonable => \&work}] } ],
        two => { three => 17, honk=>\$honk, fh=>\$fh },
        string => \"string",
    };
my $o;


# walk one time
my $S = Devel::Walk::Unstorable->new;
$S->walk( $top, '$top' );
pass( "Walked a reference" );

my @bottom = $S->list;

is_deeply( [ sort @bottom ], [ sort
    '$${$top->{array}[5]}{arraywithhash}[1]{unclonable}',
    '$${$top->{two}{fh}}' ], "Found 2 unstorables" ) or diag( join "\n", @bottom );

@bottom = unstorable( $top, '$top' );

is_deeply( [ sort @bottom ], [ sort
    '$${$top->{array}[5]}{arraywithhash}[1]{unclonable}',
    '$${$top->{two}{fh}}' ], "Found 2 unstorables" ) or diag( join "\n", @bottom );


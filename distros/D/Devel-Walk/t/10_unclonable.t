#!/usr/bin/perl

use strict;
use warnings;

use Test::More ( tests => 6 );

use Devel::Walk;
use Storable qw( freeze );
use IO::File;

my $bottom;

############################################
sub unclonable
{
    my( $loc, $obj ) = @_;
    if( !ref($obj) or eval { local $SIG{__DIE__} = 'DEFAULT'; freeze( $obj ); 1 } ) {
        note "$loc is fine";
        return;
    }
    note "$loc ($obj) is unfreezable: $@";
    $bottom = $loc;
    return 1;
}

############################################
my @everything;
sub everything
{
    my( $loc ) = @_;
    push @everything, $loc;
    return 1;
}

############################################
my $fh = IO::File->new;
my $honk;
my $top = {
        array => [ 1..3, { honk=>'bonk'}, 0, \{ arraywithhash => [10,{unclonable => \&unclonable}] } ],
        two => { three => 17, honk=>\$honk },
        string => \"string"
    };
my $o;


# walk one time
walk( $top, \&unclonable, '$top' );
# warn $${$top->{one}[4]}{unclonable};
pass( "Walked a reference" );
is( $bottom, '$${$top->{array}[5]}{arraywithhash}[1]{unclonable}', "Found one bad" );
my $val = eval $bottom;
is( $val, \&unclonable, "a code ref" );

# $do_diag = 0;

# walk again, collecting everything
walk( $top, \&everything );
#use Data::Dump qw( pp );
#warn pp [ sort @everything ];
is_deeply( [ sort @everything ], [
  '$${$o->{array}[5]}',
  '$${$o->{array}[5]}{arraywithhash}',
  '$${$o->{array}[5]}{arraywithhash}[0]',
  '$${$o->{array}[5]}{arraywithhash}[1]',
  '$${$o->{array}[5]}{arraywithhash}[1]{unclonable}',
  '$${$o->{string}}',
  '$${$o->{two}{honk}}',
  '$o',
  '$o->{array}',
  '$o->{array}[0]',
  '$o->{array}[1]',
  '$o->{array}[2]',
  '$o->{array}[3]',
  '$o->{array}[3]{honk}',
  '$o->{array}[4]',
  '$o->{array}[5]',
  '$o->{string}',
  '$o->{two}',
  '$o->{two}{honk}',
  '$o->{two}{three}',
], "walked everything" );


# walk again, without the name
delete $${$top->{array}[5]}{arraywithhash}[1]{unclonable};
$${$top->{array}[5]}{arraywithhash}[1]{file} = $fh;
$bottom = '';
walk( $top, \&unclonable );
is( $bottom, '$${$o->{array}[5]}{arraywithhash}[1]{file}', "Found one bad, with default name" );
$o = $top;
$val = eval $bottom;
is( $val, $fh, "a file ref" );


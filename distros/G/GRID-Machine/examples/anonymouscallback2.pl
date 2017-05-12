#!/usr/bin/perl
use strict;
use GRID::Machine;
use Sys::Hostname;

# This example does not work when cleanup code is in
# cleanup (-dk-) See examples/anonymouscallback2.pl
#   foreach my $id (@ids) {
#      delete $self->{callbacks}->{$id}
#   }
#

my $host = 'beowulf';

my $machine = GRID::Machine->new(
    host => $host,
    uses => [ 'Sys::Hostname' ]
);

# register remote procedure
my $r = $machine->sub( remote => q{
    my $rsub = shift;
    die "Code reference expected\n" unless UNIVERSAL::isa($rsub, 'CODE');

    gprint &hostname.": inside remote sub\n";
    my $retval = $rsub->();
    return  1+$retval;
} );

die $r->errmsg unless $r->ok;

my $a =  $machine->callback( 
           sub {
             print hostname().": inside anonymous inline callback...\n";
             return 5;
           } 
         );

$r = $machine->remote( $a );
die $r->errmsg unless $r->noerr;

$r = $machine->remote( $a );

die $r->errmsg unless $r->noerr;


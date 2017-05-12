#===============================================================================
#
#  DESCRIPTION:  Test for special type of objects in flow
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$
package Count;
use Flow;
use base 'Flow';

sub flow {
    $_[0]->{count}++;
}
1;

package main;
use Test::More qw(no_plan);
use strict;
use warnings;
use Data::Dumper;
use Flow::Splice;

#use Test::More tests => 1;                      # last test to print
{
    my $c = Count::->new;
    my $f = Flow::create_flow( Flow::Splice::->new(10), $c );
    my $p = $f->parser;
    $p->begin;
    $p->flow( 1 .. 5 );
    $p->ctl_flow(1);
    $p->flow( 1 .. 5 );
    $p->end;
    is $c->{count}, 2, 'purge by ctl_flow';
}


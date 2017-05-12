#===============================================================================
#
#  DESCRIPTION:  Test flow
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$
package Flow::Count;
use strict;
use warnings;
use Data::Dumper;
use base 'Flow';

sub begin {
    my $self = shift;
    return \@_;
}

sub flow {
    my $self = shift;
    $self->{count}++;
    \@_;
}

sub get_count {
    return $_[0]->{count};
}
1;

package MyFlow;
use base 'Flow';

1;

package main;
use strict;
use warnings;
use Test::More('no_plan');
use Data::Dumper;

#use Flow::Splice;
use_ok('Flow');
use_ok('Flow::Splice');
{
    my @array = ( 1 .. 20 );
    my $flow  = new Flow::Splice:: 10;
    my $count = new Flow::Count::;
    $flow->set_handler($count);
    $flow->run(@array);
    ok $count->{count} = 2, 'run flow ';

    my @a1 = ( 1 .. 21 );
    my $f1 = new Flow::Splice:: 10;
    my $c1 = new Flow::Count::;
    $f1->set_handler($c1);
    $f1->run(@a1);
    ok $c1->{count} = 3, '21 splice by  10';
}

{
    my $flow_count = new Flow::Count::;
    my $f1         = Flow::create_flow(
        'Flow::Splice' => 10,
        $flow_count, 'Flow::Count' => {}
    );
    $f1->run( 1 .. 11 );
    is $flow_count->get_count, 2, "create from mods";
    my $fc1 = new Flow::Count::;
    my $fc2 = new Flow::Count::;
    my $f2 =
      Flow::create_flow( 'Flow::Splice' => 11, $fc1, 'Flow::Splice' => 12 );
    my @flows = Flow::split_flow($f2);
    is scalar(@flows), 3, "split_flow mods1";
    my $f3 =
      Flow::create_flow( 'Flow::Splice' => 13, $fc2, 'Flow::Splice' => 15 );
    is scalar( Flow::split_flow($f3) ), 3, "split_flow mods2";
    my $f4 = Flow::create_flow( $f2, $f3 );
    is scalar( Flow::split_flow($f4) ), 6, "split flow for mod1 and mod2";
    $f4->run( 1 .. 13 );
    is $fc1->get_count(), 2, 'get count: 2';
    is $fc2->get_count(), 1, 'get count 1';

}

1;

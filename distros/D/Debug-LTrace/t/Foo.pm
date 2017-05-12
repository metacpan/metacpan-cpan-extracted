package FOO;
use strict;
use warnings;
use Debug::LTrace;
use Data::Dumper;

{   
    #debug is on
    my $obj = Debug::LTrace->new(qw/*/);

    inner(1);
    inner(2);
    out_outer();
}

#debug is off
inner(1);
inner(2);

    
{
    my $obj = Debug::LTrace->new(qw/*/);
    my $a = recurse(1);    
}

sub outer {

    my $a = shift;
    $a++;
    inner($a);
    inner2($a+1);
}


sub inner {
    my $a = shift;
    Dumper $a;
    return inner2($a);
}

sub inner2 {
    my $a = shift;
    return ($a, ++$a);
}

sub out_outer {
    outer(2, {aaa=>{qqq=>'www', yyy=> [1..3]}});
    my $aaa =  inner(111);
}


sub recurse {
    my $a = shift;
    $a++;
    return $a if $a > 5; 
    recurse($a);
}


package BAR;

use Debug::LTrace qw/Dumper/; #debug is on only for BAR::Dumper 

Dumper([1]);
use Data::Dumper;
FOO::out_outer();

1;

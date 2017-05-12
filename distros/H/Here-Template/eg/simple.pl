#!/usr/bin/perl

use strict;
use warnings; 

use Here::Template;

sub foo { 
    my $vars = $_[0];

    <<"    TMPL";

        Hello, my pid is <?= $$ ?>
        Or just in heredoc: $$

        Let's count to 10: <? 
            for (1..10) { 
                $here .= ($_ == 10) ? $_ : "$_, ";
            }
        ?>

        foo: <?= $vars->{foo} ?>

    TMPL
}

print foo;
print foo {foo => 'bar'};


my $name = "foo";
my @fruits = qw(apples oranges);

print <<"TMPL";
    
    Hello, $name
    <? for (@fruits) { ?>
        Fruit: $_  <? } ?>

TMPL


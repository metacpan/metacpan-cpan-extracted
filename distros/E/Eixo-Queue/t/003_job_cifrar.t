use strict;
use Test::More;

use Eixo::Queue::Job;

my $j = Eixo::Queue::Job->new(
    
    args=>{
        
        a=>5,
        b=>5
    }

);

my $s = $j->cifrar("mi-secreto");

ok($s =~ /\w/ && !ref($s), "Tenemos un string");

my $nj = Eixo::Queue::Job->new->descifrar(

    $s,

    "mi-secreto"
);

ok($nj->id eq $j->id && $nj->args->{a} ==5, "Job descifrado es correcto");

done_testing();

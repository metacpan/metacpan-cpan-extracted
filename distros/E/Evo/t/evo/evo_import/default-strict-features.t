use Evo;
use Test::More;

STRICT: {

  no strict;    ## no critic
  no warnings;
  $sfswiojsdfs = 3;
  is $sfswiojsdfs, 3;

ENABLE_STRICT: {
    eval 'use Evo; $foo';    ## no critic
    like $@, qr/Global symbol "\$foo"/i;
  }

}

FEATURE: {
  eval 'my $sub = sub($foo)  {  }';    ## no critic
  ok !$@;
}

FEATURE: {
  eval 'my sub foo {}';                ## no critic
  ok !$@;
}


done_testing;

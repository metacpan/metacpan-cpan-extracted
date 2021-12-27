#!/usr/bin/perl

# example use case
# perl -Ilib -d:Agent -MDevel::Agent::EveryThing examples/everything.pl 
use Modern::Perl;


A();

  B(2);
  
sub {
  B(3);
}->();
for(1,2,3) {
  # note, no extra depth here
  A($_);
}


eval { 
  # yes evals add 1 level to the stack
  A(5) 
};

sub A {
  B(1);
}


sub B {
  C(@_);
}

sub C {
  1 + 1;
}

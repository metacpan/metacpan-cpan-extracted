package 
  TestMe3;

use Modern::Perl;
use Moo;
use Data::Dumper;
extends 'TestMe2';

with 'Devel::Agent::AwareRole';
has funky=>(
  is=>'rw',
);

sub dumpling {
  &main::diag(Dumper(\@_));
}

sub test_a {
  my ($self,@args)=@_;
  $self->SUPER::test_a(@args);
}

1;

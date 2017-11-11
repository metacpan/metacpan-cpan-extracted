use strict;
use warnings;
use Test::More;

{
  package R1;
  use Jojo::Role;
}
{
  package R2;
  use Jojo::Role;
}
{
  package C1;
  use Jojo::Role -with;
  with 'R1';
}
{
  package C2;
  use Jojo::Role -with;
  our @ISA=('C1');
  with 'R2';
}

my $does_role = Jojo::Role->can('does_role');
ok $does_role->('C1','R1'), "Parent does own role";
ok !$does_role->('C1','R2'), "Parent does not do child's role";
ok $does_role->('C2','R1'), "Child does base's role";
ok $does_role->('C2','R2'), "Child does own role";

done_testing();

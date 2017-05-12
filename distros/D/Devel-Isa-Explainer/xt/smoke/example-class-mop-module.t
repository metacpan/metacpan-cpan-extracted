use strict;
use warnings;

use Test::Needs 'Class::MOP::Module';
use Test::More;

use Devel::Isa::Explainer qw();

# ABSTRACT: Ensure Moose::Meta::Class example works
{
  no warnings;
  *Devel::Isa::Explainer::_pp_key = sub { '' };
}
my $mro = Devel::Isa::Explainer::explain_isa('Class::MOP::Module');
diag "-\n$mro";
pass("No failures in pretty printing Moose::Meta::Class");

done_testing;


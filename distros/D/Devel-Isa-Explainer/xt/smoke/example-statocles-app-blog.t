use strict;
use warnings;

use Test::Needs 'Statocles::App::Blog';
use Test::More;

use Devel::Isa::Explainer qw();

# ABSTRACT: Ensure Moose::Meta::Class example works
{
  no warnings;
  *Devel::Isa::Explainer::_pp_key = sub { '' };
}
my $mro = Devel::Isa::Explainer::explain_isa('Statocles::App::Blog');
diag "-\n$mro";
pass("No failures in pretty printing Statocles::App::Blog");

done_testing;


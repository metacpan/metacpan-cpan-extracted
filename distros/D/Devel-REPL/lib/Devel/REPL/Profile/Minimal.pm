package Devel::REPL::Profile::Minimal;

our $VERSION = '1.003028';

use Moose;
use namespace::autoclean;

with 'Devel::REPL::Profile';

sub plugins {
  qw(History LexEnv DDS Packages Commands MultiLine::PPI);
}

sub apply_profile {
  my ($self, $repl) = @_;
  $repl->load_plugin($_) for $self->plugins;
}

1;

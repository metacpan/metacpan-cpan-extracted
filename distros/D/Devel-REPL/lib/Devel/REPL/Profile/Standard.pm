package Devel::REPL::Profile::Standard;

our $VERSION = '1.003028';

use Moose;
use namespace::autoclean;

with 'Devel::REPL::Profile';

sub plugins { qw(
  Colors
  Completion
  CompletionDriver::INC
  CompletionDriver::LexEnv
  CompletionDriver::Keywords
  CompletionDriver::Methods
  History
  LexEnv
  DDS
  Packages
  Commands
  MultiLine::PPI
  ReadLineHistory
);}

sub apply_profile {
  my ($self, $repl) = @_;
  $repl->load_plugin($_) for $self->plugins;
}

1;

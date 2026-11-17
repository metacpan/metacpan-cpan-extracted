package Holmgang::WarnEngine;
# Test engine for the CLI's constructor warnings (k42): a Langertha::Engine::Virtual
# that warns while it is built, as a real engine's notice (a setting it drops) does.
# The warning carries Perl's location, a read handle's line included.
use Moose;
extends 'Langertha::Engine::Virtual';

sub BUILD {
  open my $fh, '<', \"one\ntwo\n" or die;
  my $line = <$fh>;
  warn "temperature 0.7 is not supported by this model, using 1";
  return;
}

__PACKAGE__->meta->make_immutable;

1;

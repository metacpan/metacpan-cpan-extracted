package Holmgang::BrokenEngine;
# Test engine for the CLI's aborted run: a Langertha::Engine::Virtual whose
# format_tool_results dies like a program error, with a host path in the text.
use Moose;
extends 'Langertha::Engine::Virtual';

sub format_tool_results { die "tool results broke at /home/someone/secret/Engine.pm line 7.\n" }

__PACKAGE__->meta->make_immutable;

1;

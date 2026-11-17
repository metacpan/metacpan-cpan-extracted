package Example::Sugar::RoleDSL;
use strict;
use warnings;
use Moose::Role ();
use Moose::Exporter;
use Example::Sugar::Registry ();

Moose::Exporter->setup_import_methods(
  also => ['Moose::Role'], with_meta => [qw(step step_if)],
);
# Explicit owner flow: no caller-sensitive shim and no duplicated registration logic.
sub step {
  my ($meta, @args) = @_;
  Example::Sugar::Registry::register_step($meta->name, undef, @args);
}
sub step_if {
  my ($meta, $predicate, @args) = @_;
  Example::Sugar::Registry::register_step($meta->name, $predicate, @args);
}
1;

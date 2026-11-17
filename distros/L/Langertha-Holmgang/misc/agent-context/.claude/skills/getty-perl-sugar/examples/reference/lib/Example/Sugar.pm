package Example::Sugar;
use strict;
use warnings;
use Moose ();
use Moose::Exporter;
use Moose::Util ();
use Example::Sugar::Runner ();
use Example::Sugar::Registry ();

Moose::Exporter->setup_import_methods(
  also => ['Moose'], with_meta => [qw(step step_if)],
);
sub init_meta {
  my ($class, %args) = @_;
  my $meta = Moose->init_meta(%args);
  Moose::Util::apply_all_roles($meta->name, 'Example::Sugar::Runner')
    unless $meta->does_role('Example::Sugar::Runner');
  return $meta;
}
sub step {
  my ($meta, @args) = @_;
  Example::Sugar::Registry::register_step($meta->name, undef, @args);
}
sub step_if {
  my ($meta, $predicate, @args) = @_;
  Example::Sugar::Registry::register_step($meta->name, $predicate, @args);
}
1;

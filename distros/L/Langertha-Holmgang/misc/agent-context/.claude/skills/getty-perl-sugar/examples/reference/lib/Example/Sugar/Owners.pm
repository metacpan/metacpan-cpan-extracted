package Example::Sugar::Owners;
use strict;
use warnings;
use Class::MOP ();

sub for_class {
  my ($class) = @_;
  my $meta = Class::MOP::class_of($class) or die "No metaclass for $class\n";
  my (@owners, %seen);
  # Base-first reverse MRO is this example's policy, not a Moose guarantee.
  for my $ancestor (reverse $meta->linearized_isa) {
    my $am = Class::MOP::class_of($ancestor);
    next unless $am && $am->can('calculate_all_roles');
    my @roles = sort map { $_->name } $am->calculate_all_roles;
    for my $owner (@roles, $ancestor) {
      next if $owner eq 'Example::Sugar::Runner' || $seen{$owner}++;
      push @owners, $owner;
    }
  }
  return \@owners;
}
1;

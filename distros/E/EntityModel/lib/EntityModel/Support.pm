package EntityModel::Support;
{
  $EntityModel::Support::VERSION = '0.102';
}
use EntityModel::Class {
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Support - language support for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=head1 METHODS

=cut

=head2 register

Register with L<EntityModel> so that callbacks trigger when further definitions are loaded/processed.

=cut

sub register {
	my $class = shift;
}

=head2 apply_model

Apply the given model.

=cut

sub apply_model {
	my $self = shift;
	my $model = shift;

	my @pending = $model->entity->list;
	my @pendingNames = map { $_->name } @pending;
	my @existing;
	ITEM:
	while(@pending) {
		my $entity = shift(@pending);
		shift(@pendingNames);

		my @deps = $entity->dependencies;

		# Include current entity in list of available entries, so that we can allow self-reference
		DEP:
		foreach my $dep (@deps) {
			next DEP if $dep->name ~~ $entity->name;
			next DEP if grep { $dep->name ~~ $_ } @pendingNames;
			unless(grep { $dep->name ~~ $_->name } @existing) {
				logError("%s unresolved (pending %s, deps %s for %s)", $dep->name, join(',', @pendingNames), join(',', @deps), $entity->name);
				die "Dependency error";
			}
		}

		my @unsatisfied = grep { $_->name ~~ \@pendingNames } @deps;
		if(@unsatisfied) {
			logInfo("%s has %d unsatisfied deps, postponing: %s", $entity->name, scalar @unsatisfied, join(',',@unsatisfied));
			push @pending, $entity;
			push @pendingNames, $entity->name;
			next ITEM;
		}

		$self->apply_entity($entity);
		push @existing, $entity;
	}
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

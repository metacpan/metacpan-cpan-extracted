package EntityModel::Resolver;
{
  $EntityModel::Resolver::VERSION = '0.102';
}
use EntityModel::Class;

=head2 import

Create the helper functions in the caller's namespace.

Takes the following named parameters:

=over 4

=item * model - the model to use for resolving entities

=back

=cut

sub import {
	my $class = shift;
	my %args = @_;
	my $model = $args{model} || EntityModel->default_model;
	my $pkg = (caller)[0];

	# Now we have a better idea of what we're doing, call through
	# to the various import helpers to do the real work
	$class->import_resolve(package => $pkg, model => $model);
}

=head2 import_resolve

Takes the following named parameters:

=over 4

=item * package - the package to install this helper function into

=item * model - the model to use for resolving entities

=back

Returns

=cut

{
my %active_resolutions;
sub import_resolve {
	my $class = shift;
	my %args = @_;
	my $pkg = $args{package} or die "No package provided";
	my $model = $args{model} or die "No model provided";
	my $code = sub (&;@) {
		my $request = shift;
		my $target = shift;
		my ($storage) = $model->storage->list or die "No storage found";
		# We'll build up the results in an array...
		my @rslt;
		# ... and a list of pending tasks so we can wait on them once we have
		# a clear idea of what we're waiting for.
		my @futures;

		# So the first step is to pull our list of key,value pairs from the
		# coderef, then we can go through those to start pulling data.
		my @pending = $request->();
		while(@pending) {
			# We expect (entity_name, keyfield_value) pairs
			my ($k, $v) = splice @pending, 0, 2;

			# Helps if we have an entity with a valid keyfield:
			my $entity = $model->entity_by_name($k) or die "Entity [$k] not found";
			die "No keyfield for $entity" unless defined $entity->keyfield;

			# Stash a placeholder value at the appropriate place in the output array,
			# and prepare a future to update it when we know what the real value is.
			# TODO Something about this just doesn't sit right with me.
			push @rslt, undef;
			my $idx = $#rslt;
			my $future = Future->new->on_ready(sub {
				($rslt[$idx]) = shift->get;
			});

			# Common handler to update our future when we have the value either through insert or find
			my $handler = sub { $future->done(shift) };

			# Start with a lookup
			my $attempt = 0;
			my $search_party; $search_party = sub {
				die "This is hopeless, we've already tried $attempt times and we're not getting anywhere" if ++$attempt > 3;
				$storage->find(
					entity => $entity,
					on_item => $handler,
					on_not_found => sub {
						# Someone else might have created between our failed lookup and our
						# creation attempt, so be prepared for this ->create call to fail
						# as well.
						$storage->create(
							entity => $entity,
							data => { $entity->keyfield => $v, },
							on_complete => $handler,
							# If we fail for some reason, loop around and try again
							on_failure => $search_party,
						);
					}
				);
			};
			# Do the lookup and add to our queue
			$search_party->();
			push @futures, $future;
		}

		# We need to keep the master future around until we've finished processing,
		# so we'll stash locally and clean up on completion.
		my $future = Future->needs_all(@futures);
		my $key = "$future";
		$future->on_ready(sub {
			delete $active_resolutions{$key};
			$target->(@rslt);
		});
		$active_resolutions{$key} = $future;
	};
	{ no strict 'refs'; *{join '::', $pkg, 'resolve'} = $code }
}
}

1;


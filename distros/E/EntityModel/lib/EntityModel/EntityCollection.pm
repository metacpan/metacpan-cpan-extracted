package EntityModel::EntityCollection;
{
  $EntityModel::EntityCollection::VERSION = '0.102';
}
use EntityModel::Class {
	_isa => [qw(EntityModel::Collection)],
	query => { type => qw(EntityModel::Query) },
};

=head1 NAME

EntityModel::EntityCollection - deal with collections of entities

=head1 VERSION

version 0.102

=head1 SYNOPSIS

=cut

=head2 group

=cut

sub group {
	my $self = shift;
	my $param = shift;
	logDebug("Group by %s", $param);
	$self->query->add_group($param);
	$self->pending(1);
	return defined wantarray
	? $self
	: $self->commit
}

=head2 select

=cut

sub select : method {
	my $self = shift;
	foreach my $param (@_) {
		logDebug("Select %s", $param);
		$self->query->add_field($param);
	}
	$self->pending(1);
	return defined wantarray
	? $self
	: $self->commit
}

=head2 order

=cut

sub order {
	my $self = shift;
	foreach my $param (@_) {
		logDebug("Order by %s", $param);
		$self->query->add_order($param);
	}
	$self->pending(1);
	return defined wantarray
	? $self
	: $self->commit
}

=head2 apply

=cut

sub apply {
	my $self = shift;
	logInfo("Will run query: %s",
		'select ' . join(', ', map {
			(exists($_->{op})
			? $_->{op} . '(' . $_->{field} . ')'
			: $_->{field})
			. ' as "' . $_->{alias} . '"'
		} @{ $self->{select} })
		. ' from article'
		. ' where 1=1'
		. ' group by ' . join(', ', map {
			(exists($_->{op})
			? $_->{op} . '(' . $_->{field} . ')'
			: $_->{field})
		} @{ $self->{group} })
		. ' order by ' . join(', ', map {
			exists($_->{alias})
			? $_->{alias}
			: (exists($_->{op})
			? $_->{op} . '(' . $_->{field} . ')'
			: $_->{field})
		} @{ $self->{order} })
	);
	# $self->(item => 'xyz', map rand(1023), @{$self->{select}});
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.

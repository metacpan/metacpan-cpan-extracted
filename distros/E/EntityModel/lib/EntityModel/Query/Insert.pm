package EntityModel::Query::Insert;
{
  $EntityModel::Query::Insert::VERSION = '0.102';
}
use EntityModel::Class {
	_isa => [qw{EntityModel::Query}],
	'values' => { type => 'array', subclass => 'EntityModel::Query::InsertField' },
};

=head1 NAME

EntityModel::Query::Insert - support for INSERT SQL statement

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<Entitymodel::Query>.

=head1 DESCRIPTION

See L<Entitymodel::Query>.

=cut

=head1 METHODS

=cut

=head2 import

Register the parse handling for our 'insert' attribute.

=cut

sub import {
	my $class = shift;
	$class->register(
		'insert_into' => sub {
			my $self = shift;
			$self->upgradeTo('EntityModel::Query::Insert');
			$self->parse_base(
				@_,
				method	=> 'from',
				type	=> 'EntityModel::Query::FromTable'
			);
		}
	);
}

=head2 type

=cut

sub type { 'insert'; }

=head2 parse_values

Populate the values for the insert statement.

=cut

sub parse_values {
	my $self = shift;
	my $spec = shift;
	foreach my $k (sort keys %$spec) {
		$self->parse_base({
				name => $k,
				value => $spec->{$k},
			},
			method => 'values',
			type => 'EntityModel::Query::InsertField'
		);
	}
}

=head2 parse_fields

Populate the values for the insert statement.

=cut

sub parse_fields {
	my $self = shift;
	my $spec = shift;
	foreach my $k (sort keys %$spec) {
		$self->parse_base({
				name => $k,
				value => $spec->{$k},
			},
			method => 'values',
			type => 'EntityModel::Query::InsertField'
		);
	}
}

=head2 fieldsSQL

=cut

sub fieldsSQL {
	my $self = shift;
	logDebug("We have fields: [%s]", join(',', map { $_->field } $self->values->list));
	my $fields = join(', ', grep { defined $_ } map {
		$_->asString
	} $self->values->list);
	logDebug("Fields are [%s]", $fields);
	return unless $fields;
	return '(' . $fields . ')';
}

=head2 valuesSQL

=cut

sub valuesSQL {
	my $self = shift;
	my $sql = join(', ', grep { defined $_ } map {
		$_->quotedValue
	} $self->values->list);
	return unless $sql;
	return 'values (' . $sql . ')';
}

=head2 keyword_order

=cut

sub keyword_order { qw{type from fields values returning}; }

=head2 fromSQL

=cut

sub fromSQL {
	my $self = shift;
	my $from = join(', ', map { $_->asString } $self->from->list);
	return unless $from;
	return $from;
}

sub inlineSQL {
	my $self = shift;
	my $data = [
		'insert into ',
		(map { $_->asString } $self->from->list),
		' (',
		join(', ', map { $_->name } $self->values->list),
		') values ('
	];
	my @field;
	foreach ($self->values->list) {
		my $v = $_->value;
		push @field, ', ' if @field;
		push @field, \$v;
	}
	push @$data, @field;
	push @$data, ')';
	if($self->returning->count) {
		push @$data, ' returning ';
		push @$data, $_->asString for $self->returning->list;
	}
	return $data;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

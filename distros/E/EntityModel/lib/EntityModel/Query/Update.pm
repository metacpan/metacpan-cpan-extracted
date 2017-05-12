package EntityModel::Query::Update;
{
  $EntityModel::Query::Update::VERSION = '0.102';
}
use EntityModel::Class {
	_isa => [qw{EntityModel::Query}],
	'set' => { type => 'array', subclass => 'EntityModel::Query::Field' },
};

=head1 NAME

EntityModel::Query::Update - update statement

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
		'update' => sub {
			my $self = shift;
			$self->upgradeTo('EntityModel::Query::Update');
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

sub type { 'update'; }

=head2 parse_fields

Populate the values for the update statement.

=cut

sub parse_fields {
	my $self = shift;
	my $spec = shift;
	my @entries = ref $spec eq 'HASH' ? %$spec : @$spec;
	while(@entries) {
		my $k = shift(@entries);
		my $v = shift(@entries);
		$self->parse_base({
				name => $k,
				value => $v,
			},
			method => 'set',
			type => 'EntityModel::Query::UpdateField'
		);
	}
}

=head2 keyword_order

=cut

sub keyword_order { qw{type from join fields where order offset limit}; }

=head2 fromSQL

=cut

sub fromSQL {
	my $self = shift;
	my $from = join(', ', map { $_->asString } $self->from->list);
	return unless $from;
	return $from;
}

=head2 fieldsSQL

=cut

sub fieldsSQL {
	my $self = shift;
	my $fields = join(', ', map {
		$_->asString . ' = ' . $_->quotedValue
	} $self->set->list);
	return unless $fields;
	return 'set ' . $fields;
}

sub inlineSQL {
	my $self = shift;
	my $data = [
		'update ',
		(map { $_->asString } $self->from->list),
		' set ',
	];
	my @field;
	foreach ($self->set->list) {
		my $v = $_->value;
		push @field, ', ' if @field;
		push @field, $_->name;
		push @field, ' = ';
		push @field, \$v;
	}
	push @$data, @field;
	push @$data, ' ', @{$self->whereSQL} if $self->where;
	return $data;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

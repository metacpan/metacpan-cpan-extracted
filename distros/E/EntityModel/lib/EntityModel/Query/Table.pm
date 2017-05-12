package EntityModel::Query::Table;
{
  $EntityModel::Query::Table::VERSION = '0.102';
}
use EntityModel::Class {
	'_isa'		=> [qw(EntityModel::Query::Base)],
	'entity' 	=> { type => 'EntityModel::Entity', defer => 1 },
	'table'		=> 'string',
	'alias'		=> 'string',
};

=head1 NAME

EntityModel::Query::Table

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<Entitymodel::Query>.

=head1 DESCRIPTION

See L<Entitymodel::Query>.

=cut

=head1 METHODS

=cut

=head2 new

=cut

sub new {
	my $class = shift;
	my $self = bless { }, $class;

# Handle plain value
	if(@_ == 1 && !ref $_[0]) {
		$self->table($_[0]);
	} else {
		$self->entity($_[0]);
	}

	return $self;
}

=head2 asString

=cut

sub asString {
	my $self = shift;
	my $str = '';
	if($self->table) {
		$str = $self->table;
	} else {
		return $self->entity unless ref($self->entity);
		if(ref $self->entity eq 'HASH') {
			my ($alias, $t) = %{$self->entity};
			return "$t as $alias";
		}
		return '"' . $self->entity->schema . '"."' . $self->entity->name . '"';
	}
	$str .= ' as ' . $self->alias if $self->alias;
	return $str;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

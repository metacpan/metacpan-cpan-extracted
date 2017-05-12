package EntityModel::Query::Join;
{
  $EntityModel::Query::Join::VERSION = '0.102';
}
use EntityModel::Class {
	'table' => { type => 'EntityModel::Query::JoinTable' },
	'alias' => { type => 'string' },
	'type' => { type => 'string' },
	'on' => { type => 'array', subclass => 'EntityModel::Query::Condition' },
};

=head1 NAME

EntityModel::Query::Join - base class for JOIN tables

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<Entitymodel::Query>.

=head1 DESCRIPTION

See L<Entitymodel::Query>.

=cut

=head1 METHODS

=cut

=head2 asString

=cut

sub asString {
	my $self = shift;
	my @cond = $self->on->list;
	my $sql = $_->type . ' join ' . $self->table->asString . ' as ' . $_->alias;
	$sql .= ' on ' . join(' and ', map { $_->asString } @cond) if @cond;
	return $sql;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

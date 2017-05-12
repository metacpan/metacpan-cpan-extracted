package EntityModel::Query::SubQuery;
{
  $EntityModel::Query::SubQuery::VERSION = '0.102';
}
use EntityModel::Class {
	_isa => [qw{EntityModel::Query}],
	subquery => { type => 'array', subclass => 'EntityModel::Query' }
};

=head1 NAME

EntityModel::Query::SubQuery - subquery

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<Entitymodel::Query>.

=head1 DESCRIPTION

See L<Entitymodel::Query>.

=cut

=head1 METHODS

=cut

# We behave as a select
sub type { 'select'; }

sub subtype { die 'virtual method subtype called'; }

sub inlineSQL {
	my $self = shift;
	my @sql;
	my @sub = $self->subquery->list;
	while(@sub) {
		my $entry = shift(@sub);
		push @sql, '(';
		push @sql, @{ $entry->inlineSQL };
		push @sql, ')';
		push @sql, ' ' . $self->subtype . ' ' if @sub;
	}
	return \@sql;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

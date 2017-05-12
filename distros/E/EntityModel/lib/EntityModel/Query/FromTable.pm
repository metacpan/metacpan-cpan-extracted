package EntityModel::Query::FromTable;
{
  $EntityModel::Query::FromTable::VERSION = '0.102';
}
use EntityModel::Class {
	_isa => [qw(EntityModel::Query::Table)],
};

=head1 NAME

EntityModel::Query::FromTable - FROM table definition

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

Register parse handling.

=cut

sub import {
	my $class = shift;
	$class->register(
		'from' => sub {
			my $self = shift;
			$self->parse_base(
				@_,
				method	=> 'from',
				type	=> 'EntityModel::Query::FromTable'
			);
		}
	);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

package EntityModel::Query::Select;
{
  $EntityModel::Query::Select::VERSION = '0.102';
}
use EntityModel::Class {
	_isa => [qw{EntityModel::Query}],
};

=head1 NAME

EntityModel::Query::Select - select statement definition

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

Register the parse handling for our 'select' attribute.

=cut

sub import {
	my $class = shift;
	$class->register(
		'select' => sub {
			my $self = shift;
			$self->upgradeTo('EntityModel::Query::Select');
			$self->parse_base(
				@_,
				method	=> 'field',
				type	=> 'EntityModel::Query::Field'
			);
		}
	);
}

=head2 type

=cut

sub type { 'select'; }

=head2 keyword_order

=cut

sub keyword_order { qw{type fields from join where having group order offset limit}; }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

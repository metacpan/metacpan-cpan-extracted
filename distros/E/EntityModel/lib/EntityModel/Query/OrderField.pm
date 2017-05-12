package EntityModel::Query::OrderField;
{
  $EntityModel::Query::OrderField::VERSION = '0.102';
}
use EntityModel::Class {
	_isa => [qw{EntityModel::Query::Field}],
	direction => { type => 'int' }
};

=head1 NAME

EntityModel::Query::OrderField - define a field for ORDER BY clause

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
		'order' => sub {
			my $self = shift;
			my $v = shift;
			my @comp = (ref $v eq 'ARRAY') ? @$v : $v;

			foreach my $entry (@comp) {
				if(ref $entry eq 'HASH') {
					my ($dir, $field) = %$entry;

					my $o = EntityModel::Query::OrderField->new($field);
					$o->direction($dir eq 'desc' ? 1 : 0);
					$self->order->push($o);
				} else {
					my $o = EntityModel::Query::OrderField->new($entry);
					$self->order->push($o);
				}
			}
			return $self;
		}
	);
}

=head2 asString

=cut

sub asString {
	my $self = shift;
	return $self->SUPER::asString(@_) . ($self->direction ? ' desc' : '');
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

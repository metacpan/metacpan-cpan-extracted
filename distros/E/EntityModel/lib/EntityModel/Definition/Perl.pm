package EntityModel::Definition::Perl;
{
  $EntityModel::Definition::Perl::VERSION = '0.102';
}
use EntityModel::Class {
	_isa		=> [qw{EntityModel::Definition}],
};

=head1 NAME

EntityModel::Definition::Perl - definition support for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=head1 METHODS

=cut

=head2 load

Perl is simple - give it a hashref, let it sort things out for itself.

=cut

sub load {
	my $self = shift;
	my %args = @_;
	my $src = delete $args{source};
	return $self->apply_model_from_structure(
		model		=> $args{model},
		structure	=> $src
	);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

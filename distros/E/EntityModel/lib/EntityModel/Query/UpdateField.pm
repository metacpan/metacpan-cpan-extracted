package EntityModel::Query::UpdateField;
{
  $EntityModel::Query::UpdateField::VERSION = '0.102';
}
use EntityModel::Class {
	'_isa' => [qw(EntityModel::Query::Field)],
	'value' => 'string',
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Query::UpdateField - field to be updated in an update statement

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<Entitymodel::Query>.

=head1 DESCRIPTION

See L<Entitymodel::Query>.

=cut

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = bless { }, $class;
	my $args = shift;
	my @spec;
	if(ref $args ~~ 'HASH') {
		push @spec, %$args;
	} elsif(ref $args ~~ 'ARRAY') {
		push @spec, @$args;
	} else {
		die "no idea what $args is";
	}

	while(@spec) {
		my $k = shift(@spec);
		my $v = shift(@spec);
		$self->$k($v);
	}
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

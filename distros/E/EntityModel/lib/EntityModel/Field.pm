package EntityModel::Field;
{
  $EntityModel::Field::VERSION = '0.102';
}
use EntityModel::Class {
	'name'		=> { type => 'string' },
	'default'	=> { type => 'string' },
	'null'		=> { type => 'bool' },
	'type'		=> { type => 'string' },
	'length'	=> { type => 'int' },
	'description'	=> { type => 'string' },
	'precision'	=> { type => 'int' },
	'scale'		=> { type => 'int' },
	'unique'	=> { type => 'bool' },
	'refer'		=> { type => 'EntityModel::Field::Refer' },
};

use overload '""' => sub { 'field:' . shift->name }, fallback => 1;

=head1 NAME

EntityModel::Field - field definitions for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=cut

sub method { shift->name }

sub create_from_definition {
	my $class = shift;
	my $def = shift;
	my $self = $class->new;

# Should only have one of these but we treat all nested elements as arrays in our definitions.
	foreach my $refer_def (@{delete($def->{refer}) // []}) {
		my $refer = EntityModel::Field::Refer->new;
		$refer->$_($refer_def->{$_}) foreach keys %$refer_def;
		$self->refer($refer);
	}

# Use the accessors so that we die satisfactorily when provided with anything invalid.
	$self->$_($def->{$_}) foreach keys %$def;
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.

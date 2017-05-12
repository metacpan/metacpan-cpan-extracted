package EntityModel::Web::Page::Data;
{
  $EntityModel::Web::Page::Data::VERSION = '0.004';
}
use EntityModel::Class {
	key		=> { type => 'string' },
	value		=> { type => 'string' },
	class		=> { type => 'string' },
	instance	=> { type => 'string' },
	method		=> { type => 'string' },
	data		=> { type => 'string' },
	parameter	=> { type => 'array', subclass => 'EntityModel::Web::Page::Data' },
};

=pod

Accepts the following items:

=over 4

=item * key - the name to assign to this data value

=item * value - static value to assign

=item * class - a class to call a method on

=item * instance - an instance on which to call the given method

=item * method - a method to call

=item * data - an existing data item

=item * param - parameters to pass to the method

=back

=cut

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my %args = ref $_[0] ? %{$_[0]} : @_;

	foreach my $item (qw(key value class method instance data)) {
		if(defined(my $v = delete $args{$item})) {
			$self->$item($v);
		}
	}

# Recurse for any defined parameters
	if(defined(my $param = delete $args{parameter})) {
		foreach my $p (@$param) {
			$self->parameter->push(
				EntityModel::Web::Page::Data->new(%$p)
			);
		}
	}
	return $self;
}

1;


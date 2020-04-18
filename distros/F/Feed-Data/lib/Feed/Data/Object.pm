package Feed::Data::Object;

our $VERSION = '0.01';
use Moo;
use Carp qw/croak/;
use Class::Load qw/load_class/;
use Compiled::Params::OO qw/cpo/;
use Types::Standard qw/Object Str HashRef/;

our $validate;
BEGIN {
	$validate = cpo(
		render => [Object, Str],
		generate => [Object, Str],
	);
}

has 'object' => (
	is  => 'ro',
	isa => HashRef,
	lazy => 1,
	default => sub { { } },
	handles_via => 'Hash',
	handles => {
		object_keys => 'keys',
		fields => 'get',
		edit   => 'set',
	},
);

my @fields = qw(title description image date author category permalink comment link content);
foreach my $field (@fields){
	has $field => (
		is => 'ro',
		lazy => 1,
		isa => Object,
	   	default => sub {
			my $self = shift;
			my $class = 'Feed::Data::Object::' . ucfirst($field);
			load_class($class);
			return $class->new(raw => $self->object->{$field});
		}
	);
}

sub render {
	my ( $self, $format ) = $validate->render->(@_);
	$format ||= 'text';
	my @render;
	foreach my $key (sort keys %{ $self->object }) {
		my $field = $self->$key;
		my $type = $format;
		if ($type =~ m/text|raw/) {
			push @render, sprintf "%s:%s", $key, $field->$type;
		} else {
			push @render, $field->$type;
		}
	}
	return join "\n", @render;
}

sub generate {
	my ( $self, $format ) = $validate->render->(@_);
	$format ||= 'text';
	my %object;
	for my $key ( keys %{ $self->object } ) {
		my $field = $self->$key;
		my $type = $format;
		$object{$key} = $self->$key->$type; 
	}
	return \%object;
}

1; # End of Feed::Data

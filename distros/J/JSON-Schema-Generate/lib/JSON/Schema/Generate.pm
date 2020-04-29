package JSON::Schema::Generate;

use 5.006;
use strict;
use warnings;
use Tie::IxHash;

our $VERSION = '0.02';
use Types::Standard qw/Str/;
use Compiled::Params::OO qw/cpo/;
use JSON;

our ($validate, $JSON);
BEGIN {
	$validate = cpo(
		new => {
			id => {
				type => Str,
				default => sub {
					'http://example.com/root.json'
				}
			},
			title => {
				type => Str,
				default => sub {
					'The Root Schema'
				}
			},
			description => {
				type => Str,
				default => sub {
					'The root schema is the schema that comprises the entire JSON document.'
				}
			},
			schema => {
				type => Str,
				default => sub {
					'http://json-schema.org/draft-07/schema#'
				}
			}
		}
	);
	$JSON = JSON->new->pretty;
}

sub new {
	my $class = shift;
	my $args = $validate->new->(@_);
	my $self = bless {}, $class;
	$self->{schema} = _tie_hash();
	$self->{schema}{'$schema'} = $args->schema;
	$self->{schema}{'$id'} = $args->id;
	$self->{schema}{title} = $args->title;
	$self->{schema}{description} = $args->description;
	return $self;
}

sub learn {
	$_[0]->{data} = $JSON->decode($_[1]);
	$_[0]->{data_runs}++;
	$_[0]->_build_props($_[0]->{schema}, $_[0]->{data}, '#');
	return $_[0];
}

sub generate {
	my ($self) = @_;
	$self->_handle_required($self->{schema});
	return $JSON->encode($_[0]->{schema});
}

sub _handle_required {
	my ($self, $schema) = @_;
	my $total_runs = $self->{data_runs};
	if ($schema->{required}) {
		my @required;
		for my $key (keys %{$schema->{required}}) {
			if ($schema->{required}->{$key} == $total_runs) {
				push @required, $key;
			}
		}
		$schema->{required} = \@required;
	}
	if ($schema->{properties}) {
		$self->_handle_required($schema->{properties}{$_}) for keys %{$schema->{properties}};
	}
	$self->_handle_required($schema->{items}) if $schema->{items};
}

sub _build_props {
	my ($self, $props, $data, $path) = @_;

	my $ref = ref $data;

	if ($ref eq 'HASH') {
		$self->_add_type($props, 'object');
		$self->_unique_examples($props, $data);
		return if ref $props->{type};
		if (!$props->{properties}) {
			$props->{required} = {};
			$props->{properties} = _tie_hash();
		}
		for my $key (sort keys %{$data}) {
			$props->{required}->{$key}++;
			my $id = $path . '/properties/' . $key;
			unless ($props->{properties}{$key}) {
				$props->{properties}{$key} = _tie_hash();
				$props->{properties}{$key}{'$id'} = $id;
				$props->{properties}{$key}{title} = 'The ' . ucfirst($key) . ' Schema';
				$props->{properties}{$key}{description} = 'An explanation about the purpose of this instance.';
			}
			$self->_build_props($props->{properties}{$key}, $data->{$key}, $id);
		}
	} elsif ($ref eq 'ARRAY') {
		$self->_add_type($props, 'array');
		my $id = $path . '/items';
		unless ($props->{items}) {
			$props->{items} = _tie_hash();
			$props->{items}{'$id'} = $id;
			$props->{items}{title} = 'The Items Schema';
			$props->{items}{description} = 'An explanation about the purpose of this instance.';
		}
		map {
			$self->_build_props($props->{items}, $_, $id);
		} @{$data}
	} elsif (! defined $data) {
		$self->_add_type($props, 'null');
		$self->_unique_examples($props, undef);
	} elsif ($ref eq 'SCALAR' || $ref =~ m/Boolean$/) {
		$self->_add_type($props, 'boolean');
		$self->_unique_examples($props, \1, \0);
	} elsif ($data =~ m/^\d+$/) {
		$self->_add_type($props, 'integer');
		$self->_unique_examples($props, $data);
	} elsif ($data =~ m/^\d+\.\d+$/) {
		$self->_add_type($props, 'number');
		$self->_unique_examples($props, $data);
#	} elsif ($data =~ m/\d{4}\-\d{2}\-\d{2}T\d{2}\:\d{2}\:\d{2}\+\d{2}\:\d{2}/) {
#		$self->_add_type($props, 'date-time');
#		$self->_unique_examples($props, $data);
	} else {
		$self->_add_type($props, 'string');
		$self->_unique_examples($props, $data);
	}

	return $props;
}

sub _tie_hash {
	my %properties;
	tie %properties, 'Tie::IxHash';
	return \%properties;
}

sub _add_type {
	my ($self, $props, $type) = @_;
	if (!$props->{type}) {
		$props->{type} = $type;
	} elsif ($props->{type} ne $type) {
		$props->{type} = [ $props->{type} ] unless ref $props->{type};
		push @{$props->{type}}, $type;
	}
}

sub _unique_examples {
	my ($self, $props, @examples) = @_;
	for my $example (@examples) {
		unless (grep { $_ eq $example } @{$props->{examples}}) {
			push @{$props->{examples}}, $example;
		}
	}
}

1;

__END__

=head1 NAME

JSON::Schema::Generate - Generate JSON Schemas from data!

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	use JSON::Schema::Generate;

	my $data = '{
		"checked": false,
		"dimensions": {
			"width": 10,
			"height": 10
		},
		"id": 1,
		"name": "Opposite",
		"distance": 435,
		"tags": [
			{ "date-time": "2020-02-24T10:00:00+00:00" }
		]
	}';

	my $schema = JSON::Schema::Generate->new(
		id => 'https://flat.world-wide.world/schema',
		title => '...'
		description => '...',
	)->learn($data)->generate;

	use JSON::Schema;
	my $validator = JSON::Schema->new($schema);
	my $result = $validator->validate($data);

=head1 SUBROUTINES/METHODS

=head2 learn

=cut

=head2 generate

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-json-schema-generate at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSON-Schema-Generate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JSON::Schema::Generate

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=JSON-Schema-Generate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JSON-Schema-Generate>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/JSON-Schema-Generate>

=item * Search CPAN

L<https://metacpan.org/release/JSON-Schema-Generate>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of JSON::Schema::Generate

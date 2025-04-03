package JSON::Schema::Generate;
use 5.006; use strict; use warnings; our $VERSION = '0.12';
use Tie::IxHash; use Types::Standard qw/Str HashRef Bool/;
use Compiled::Params::OO qw/cpo/; use JSON; use Blessed::Merge;

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
			},
			spec => {
				type => HashRef,
				default => sub { { } }
			},
			merge_examples => {
				type => Bool,
				default => sub { !!0 }
			},
			none_required => {
				type => Bool,
				default => sub { !!0 }
			},
			no_id => {
				type => Bool,
				default => sub { !!0 }
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
	$self->{$_} = $args->$_ for qw/spec merge_examples none_required no_id/;
	if ($args->merge_examples) {
		$self->{merge} = Blessed::Merge->new(
			blessed => 0,
			unique_array => 1,
			unique_hash => 1,
			same => 0
		);
	}
	return $self;
}

sub learn {
	$_[0]->{data} = ref $_[1] ? $_[1] : $JSON->decode($_[1]);
	$_[0]->{data_runs}++;
	$_[0]->_build_props($_[0]->{schema}, $_[0]->{data}, '#');
	return $_[0];
}

sub generate {
	my ($self, $struct) = @_;
	$self->_handle_required($self->{schema}) unless $self->{none_required};
	return $struct ? $self->{schema} : $JSON->encode($self->{schema});
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
			$props->{required} = {} unless $self->{none_required};
			$props->{properties} = _tie_hash();
		}
		for my $key (sort keys %{$data}) {
			$props->{required}->{$key}++ unless $self->{none_required};
			my $id = $path . ( $path eq '#' ? '' : '-' ) . 'properties-' . $key;
			unless ($props->{properties}{$key}) {
				$props->{properties}{$key} = _tie_hash();
				%{$props->{properties}{$key}} = (
					($self->{no_id} ? () : ('$id' => $id)),
					title => 'The title',
					description => 'An explanation about the purpose of this instance',
					($self->{spec}->{$key} ? %{$self->{spec}->{$key}} : ())
				);
			}
			$self->_build_props($props->{properties}{$key}, $data->{$key}, $id);
		}
	} elsif ($ref eq 'ARRAY') {
		$self->_add_type($props, 'array');
		my $id = $path . '-items';
		unless ($props->{items}) {
			$props->{items} = _tie_hash();
			$props->{items}{'$id'} = $id unless $self->{no_id};
			$props->{items}{title} = 'The Items Schema';
			$props->{items}{description} = 'An explanation about the purpose of this instance.';
		}
		map {
			$self->_build_props($props->{items}, $_, $id);
		} @{$data}
	} elsif (! defined $data) {
		$self->_add_type($props, 'null');
		$self->_unique_examples($props, undef);
	} elsif ($ref eq 'SCALAR' or $ref =~ m/Boolean$/i) {
		$self->_add_type($props, 'boolean');
		$self->_unique_examples($props, \1, \0);
	} elsif ($data =~ m/^\d+$/) {
		$self->_add_type($props, 'integer');
		$self->_unique_examples($props, $data);
	} elsif ($data =~ m/^\d+\.\d+$/) {
		$self->_add_type($props, 'number');
		$self->_unique_examples($props, $data);
	} elsif ($data =~ m/\d{4}\-\d{2}\-\d{2}T\d{2}\:\d{2}\:\d{2}\+\d{2}\:\d{2}/) {
		$self->_add_type($props, 'date-time');
		$self->_unique_examples($props, $data);
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
		push @{$props->{type}}, $type unless grep { $type eq $_ } @{$props->{type}};
	}
}

sub _unique_examples {
	my ($self, $props, @examples) = @_;
	for my $example (@examples) {
		if ((ref($example) || 'SCALAR') ne 'SCALAR' && $props->{examples} && $self->{merge_examples}) {
			$props->{examples}->[0] = $self->{merge}->merge($props->{examples}->[0], $example);
		} else {
			unless (grep { ($_//"") eq ($example//"") } @{$props->{examples}}) {
				push @{$props->{examples}}, $example;
			}
		}
	}
}

1;

__END__

=head1 NAME

JSON::Schema::Generate - Generate JSON Schemas from data!

=head1 VERSION

Version 0.12

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
		spec => {
			name => {
				title => '...',
				description => '...'
			},
			...
		}
	)->learn($data)->generate;

	use JSON::Schema;
	my $validator = JSON::Schema->new($schema);
	my $result = $validator->validate($data);

	...

	use JSON::Schema::Draft201909;
	my $schema = JSON::Schema::Generate->new(
		no_id => 1
	)->learn($data)->generate(1);

	$js = JSON::Schema::Draft201909->new;
	$result = $js->evaluate_json_string($data, $schema);

	...

	use JSON::Schema::Modern;

	$data = json_decode($data);

	my $schema = JSON::Schema::Generate->new(
		id => 'https://flat.world-wide.world/schema',
		title => '...'
		description => '...',
	)->learn($data)->generate(1);

	$js = JSON::Schema::Modern->new(
		specification_version => 'draft2020-12',
	);

	$result = $js->evaluate($data, $schema);


=head1 DESCRIPTION

JSON::Schema::Generate is a tool allowing you to derive JSON Schemas from a set of data.

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new JSON::Schema::Generate Object

	my $schema = JSON::Schema->new(
		...
	);

It accepts the following parameters:

=over

=item id

The root $id of the schema. default: http://example.com/root.json

=item title

The root title of the schema. default: The Root Schema

=item description

The root description of the schema. default: The root schema is the schema that comprises the entire JSON document.

=item schema

The root schema version. default: 'http://json-schema.org/draft-07/schema#'

=item spec

A mapping hash reference that represent a key inside of the passed data and a value that contains additional metadata to be added to the schema. default: {}

=item merge_examples

Merge all learn data examples into a single example. default: false

=item none_required

Do not analyse required keys in properties. default: false.

=item no_id

Do not add $id(s) to properties and items. default: false. 

=back

=head2 learn

Accepts a JSON string, Hashref or ArrayRef that it will traverse to build a valid JSON schema. Learn can be chained allowing you to build a schema from multiple data sources.

	$schema->learn($data1)->learn($data2)->learn($data3);

=cut

=head2 generate

Compiles the learned data and generates the final JSON schema in JSON format.

	$schema->generate();

Optionally you can pass a boolean (true value) which will return the schema as a perl struct.

	$schema->generate(1)

=cut

=head1 EXAMPLE

	use JSON::Schema::Generate;

	my $data1 = '{
		"links" : {
			"cpantesters_reports" : "http://cpantesters.org/author/L/LNATION.html",
			"cpan_directory" : "http://cpan.org/authors/id/L/LN/LNATION",
			"metacpan_explorer" : "https://explorer.metacpan.org/?url=/author/LNATION",
			"cpantesters_matrix" : "http://matrix.cpantesters.org/?author=LNATION",
			"cpants" : "http://cpants.cpanauthors.org/author/LNATION",
			"backpan_directory" : "https://cpan.metacpan.org/authors/id/L/LN/LNATION"
		},
		"city" : "PLUTO",
		"updated" : "2020-02-16T16:43:51",
		"region" : "GHANDI",
		"is_pause_custodial_account" : false,
		"country" : "WO",
		"website" : [
			"https://www.lnation.org"
		],
		"asciiname" : "Robert Acock",
		"gravatar_url" : "https://secure.gravatar.com/avatar/8e509558181e1d2a0d3a5b55dec0b108?s=130&d=identicon",
		"pauseid" : "LNATION",
		"email" : [
			"lnation@cpan.org"
		],
		"release_count" : {
			"cpan" : 378,
			"backpan-only" : 34,
			"latest" : 114
		},
		"name" : "Robert Acock"
	}';

	my $data2 = '{
		"asciiname" : "",
		"release_count" : {
			"latest" : 56,
			"backpan-only" : 358,
			"cpan" : 190
		},
		"name" : "Damian Conway",
		"email" : "damian@conway.org",
		"is_pause_custodial_account" : false,
		"gravatar_url" : "https://secure.gravatar.com/avatar/3d4a6a089964a744d7b3cf2415f81951?s=130&d=identicon",
		"links" : {
			"cpants" : "http://cpants.cpanauthors.org/author/DCONWAY",
			"cpan_directory" : "http://cpan.org/authors/id/D/DC/DCONWAY",
			"cpantesters_matrix" : "http://matrix.cpantesters.org/?author=DCONWAY",
			"cpantesters_reports" : "http://cpantesters.org/author/D/DCONWAY.html",
			"backpan_directory" : "https://cpan.metacpan.org/authors/id/D/DC/DCONWAY",
			"metacpan_explorer" : "https://explorer.metacpan.org/?url=/author/DCONWAY"
		},
		"pauseid" : "DCONWAY",
		"website" : [
			"http://damian.conway.org/"
		]
	}';

	my $schema = JSON::Schema::Generate->new(
		id => 'https://metacpan.org/author.json',
		title => 'The CPAN Author Schema',
		description => 'A representation of a cpan author.',
	)->learn($data1)->learn($data2)->generate;

Will generate the following schema:
	
	{
		"$schema" : "http://json-schema.org/draft-07/schema#",
		"$id" : "https://metacpan.org/author.json",
		"title" : "The CPAN Author Schema",
		"description" : "A representation of a cpan author.",
		"type" : "object",
		"examples" : [
			{
				"region" : "GHANDI",
				"gravatar_url" : "https://secure.gravatar.com/avatar/8e509558181e1d2a0d3a5b55dec0b108?s=130&d=identicon",
				"is_pause_custodial_account" : false,
				"asciiname" : "Robert Acock",
				"release_count" : {
					"backpan-only" : 34,
					"latest" : 114,
					"cpan" : 378
				},
				"country" : "WO",
				"city" : "PLUTO",
				"pauseid" : "LNATION",
				"links" : {
					"cpants" : "http://cpants.cpanauthors.org/author/LNATION",
					"metacpan_explorer" : "https://explorer.metacpan.org/?url=/author/LNATION",
					"cpantesters_reports" : "http://cpantesters.org/author/L/LNATION.html",
					"cpan_directory" : "http://cpan.org/authors/id/L/LN/LNATION",
					"cpantesters_matrix" : "http://matrix.cpantesters.org/?author=LNATION",
					"backpan_directory" : "https://cpan.metacpan.org/authors/id/L/LN/LNATION"
				},
				"updated" : "2020-02-16T16:43:51",
				"website" : [
					"https://www.lnation.org"
				],
				"name" : "Robert Acock",
				"email" : [
					"lnation@cpan.org"
				]
			},
			{
				"is_pause_custodial_account" : false,
				"gravatar_url" : "https://secure.gravatar.com/avatar/3d4a6a089964a744d7b3cf2415f81951?s=130&d=identicon",
				"asciiname" : "",
				"release_count" : {
					"backpan-only" : 358,
					"latest" : 56,
					"cpan" : 190
				},
				"links" : {
					"cpan_directory" : "http://cpan.org/authors/id/D/DC/DCONWAY",
					"cpantesters_reports" : "http://cpantesters.org/author/D/DCONWAY.html",
					"cpants" : "http://cpants.cpanauthors.org/author/DCONWAY",
					"metacpan_explorer" : "https://explorer.metacpan.org/?url=/author/DCONWAY",
					"backpan_directory" : "https://cpan.metacpan.org/authors/id/D/DC/DCONWAY",
					"cpantesters_matrix" : "http://matrix.cpantesters.org/?author=DCONWAY"
				},
				"pauseid" : "DCONWAY",
				"website" : [
					"http://damian.conway.org/"
				],
				"email" : "damian@conway.org",
				"name" : "Damian Conway"
			}
		],
		"required" : [
			"asciiname",
			"gravatar_url",
			"is_pause_custodial_account",
			"release_count",
			"pauseid",
			"links",
			"name",
			"email",
			"website"
		],
		"properties" : {
			"asciiname" : {
				"$id" : "#properties-asciiname",
				"title" : "The Asciiname Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "string",
				"examples" : [
					"Robert Acock",
					""
				]
			},
			"city" : {
				"$id" : "#properties-city",
				"title" : "The City Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "string",
				"examples" : [
					"PLUTO"
				]
			},
			"country" : {
				"$id" : "#properties-country",
				"title" : "The Country Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "string",
				"examples" : [
					"WO"
				]
			},
			"email" : {
				"$id" : "#properties-email",
				"title" : "The Email Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : [
					"array",
					"string"
				],
				"items" : {
					"$id" : "#properties-email-items",
					"title" : "The Items Schema",
					"description" : "An explanation about the purpose of this instance.",
					"type" : "string",
					"examples" : [
						"lnation@cpan.org"
					]
				},
				"examples" : [
					"damian@conway.org"
				]
			},
			"gravatar_url" : {
				"$id" : "#properties-gravatar_url",
				"title" : "The Gravatar_url Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "string",
				"examples" : [
					"https://secure.gravatar.com/avatar/8e509558181e1d2a0d3a5b55dec0b108?s=130&d=identicon",
					"https://secure.gravatar.com/avatar/3d4a6a089964a744d7b3cf2415f81951?s=130&d=identicon"
				]
			},
			"is_pause_custodial_account" : {
				"$id" : "#properties-is_pause_custodial_account",
				"title" : "The Is_pause_custodial_account Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "boolean",
				"examples" : [
					true,
					false
				]
			},
			"links" : {
				"$id" : "#properties-links",
				"title" : "The Links Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "object",
				"examples" : [
					{
						"cpants" : "http://cpants.cpanauthors.org/author/LNATION",
						"metacpan_explorer" : "https://explorer.metacpan.org/?url=/author/LNATION",
						"cpantesters_reports" : "http://cpantesters.org/author/L/LNATION.html",
						"cpan_directory" : "http://cpan.org/authors/id/L/LN/LNATION",
						"cpantesters_matrix" : "http://matrix.cpantesters.org/?author=LNATION",
						"backpan_directory" : "https://cpan.metacpan.org/authors/id/L/LN/LNATION"
					},
					{
						"cpan_directory" : "http://cpan.org/authors/id/D/DC/DCONWAY",
						"cpantesters_reports" : "http://cpantesters.org/author/D/DCONWAY.html",
						"cpants" : "http://cpants.cpanauthors.org/author/DCONWAY",
						"metacpan_explorer" : "https://explorer.metacpan.org/?url=/author/DCONWAY",
						"backpan_directory" : "https://cpan.metacpan.org/authors/id/D/DC/DCONWAY",
						"cpantesters_matrix" : "http://matrix.cpantesters.org/?author=DCONWAY"
					}
				],
				"required" : [
					"cpantesters_matrix",
					"backpan_directory",
					"metacpan_explorer",
					"cpants",
					"cpantesters_reports",
					"cpan_directory"
				],
				"properties" : {
					"backpan_directory" : {
						"$id" : "#properties-links-properties-backpan_directory",
						"title" : "The Backpan_directory Schema",
						"description" : "An explanation about the purpose of this instance.",
						"type" : "string",
						"examples" : [
							"https://cpan.metacpan.org/authors/id/L/LN/LNATION",
							"https://cpan.metacpan.org/authors/id/D/DC/DCONWAY"
						]
					},
					"cpan_directory" : {
						"$id" : "#properties-links-properties-cpan_directory",
						"title" : "The Cpan_directory Schema",
						"description" : "An explanation about the purpose of this instance.",
						"type" : "string",
						"examples" : [
							"http://cpan.org/authors/id/L/LN/LNATION",
							"http://cpan.org/authors/id/D/DC/DCONWAY"
						]
					},
					"cpantesters_matrix" : {
						"$id" : "#properties-links-properties-cpantesters_matrix",
						"title" : "The Cpantesters_matrix Schema",
						"description" : "An explanation about the purpose of this instance.",
						"type" : "string",
						"examples" : [
							"http://matrix.cpantesters.org/?author=LNATION",
							"http://matrix.cpantesters.org/?author=DCONWAY"
						]
					},
					"cpantesters_reports" : {
						"$id" : "#properties-links-properties-cpantesters_reports",
						"title" : "The Cpantesters_reports Schema",
						"description" : "An explanation about the purpose of this instance.",
						"type" : "string",
						"examples" : [
							"http://cpantesters.org/author/L/LNATION.html",
							"http://cpantesters.org/author/D/DCONWAY.html"
						]
					},
					"cpants" : {
						"$id" : "#properties-links-properties-cpants",
						"title" : "The Cpants Schema",
						"description" : "An explanation about the purpose of this instance.",
						"type" : "string",
						"examples" : [
							"http://cpants.cpanauthors.org/author/LNATION",
							"http://cpants.cpanauthors.org/author/DCONWAY"
						]
					},
					"metacpan_explorer" : {
						"$id" : "#properties-links-properties-metacpan_explorer",
						"title" : "The Metacpan_explorer Schema",
						"description" : "An explanation about the purpose of this instance.",
						"type" : "string",
						"examples" : [
							"https://explorer.metacpan.org/?url=/author/LNATION",
							"https://explorer.metacpan.org/?url=/author/DCONWAY"
						]
					}
				}
			},
			"name" : {
				"$id" : "#properties-name",
				"title" : "The Name Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "string",
				"examples" : [
					"Robert Acock",
					"Damian Conway"
				]
			},
			"pauseid" : {
				"$id" : "#properties-pauseid",
				"title" : "The Pauseid Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "string",
				"examples" : [
					"LNATION",
					"DCONWAY"
				]
			},
			"region" : {
				"$id" : "#properties-region",
				"title" : "The Region Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "string",
				"examples" : [
					"GHANDI"
				]
			},
			"release_count" : {
				"$id" : "#properties-release_count",
				"title" : "The Release_count Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "object",
				"examples" : [
					{
						"backpan-only" : 34,
						"latest" : 114,
						"cpan" : 378
					},
					{
						"backpan-only" : 358,
						"latest" : 56,
						"cpan" : 190
					}
				],
				"required" : [
					"latest",
					"backpan-only",
					"cpan"
				],
				"properties" : {
					"backpan-only" : {
						"$id" : "#properties-release_count-properties-backpan-only",
						"title" : "The Backpan-only Schema",
						"description" : "An explanation about the purpose of this instance.",
						"type" : "integer",
						"examples" : [
							34,
							358
						]
					},
					"cpan" : {
						"$id" : "#properties-release_count-properties-cpan",
						"title" : "The Cpan Schema",
						"description" : "An explanation about the purpose of this instance.",
						"type" : "integer",
						"examples" : [
							378,
							190
						]
					},
					"latest" : {
						"$id" : "#properties-release_count-properties-latest",
						"title" : "The Latest Schema",
						"description" : "An explanation about the purpose of this instance.",
						"type" : "integer",
						"examples" : [
							114,
							56
						]
					}
				}
			},
			"updated" : {
				"$id" : "#properties-updated",
				"title" : "The Updated Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "string",
				"examples" : [
					"2020-02-16T16:43:51"
				]
			},
			"website" : {
				"$id" : "#properties-website",
				"title" : "The Website Schema",
				"description" : "An explanation about the purpose of this instance.",
				"type" : "array",
				"items" : {
					"$id" : "#properties-website-items",
					"title" : "The Items Schema",
					"description" : "An explanation about the purpose of this instance.",
					"type" : "string",
					"examples" : [
						"https://www.lnation.org",
						"http://damian.conway.org/"
					]
				}
			}
		}
	}

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

This software is Copyright (c) 2020->2021 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of JSON::Schema::Generate

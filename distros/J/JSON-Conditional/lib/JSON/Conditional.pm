package JSON::Conditional;
use 5.006; use strict; use warnings; our $VERSION = '0.05';
use JSON; use base 'Struct::Conditional';

our $JSON;

BEGIN {
	$JSON = JSON->new->pretty(1)->allow_blessed->convert_blessed;
}

sub encode {
	if ($_[2]) {
		$_[0]->encode_file($_[1], $_[2]);
	}
	$JSON->encode($_[1]);
}

sub encode_file {
	open my $file, '>', $_[2] or die "cannot open file $!";
	print $file $_[0]->encode($_[1]);
	close $file;
	return $file;
}

sub decode {
	if ( $_[1] !~ m/\n/ && -f $_[1]) {
		$_[0]->decode_file($_[1]);
	} 
	$JSON->decode($_[1]);
}

sub decode_file {
	open my $file, '<', $_[1] or die "cannot open file $!";
	my $content = do { local $/; <$file> };
	close $file;
	return $_[0]->decode($content);
}

sub compile {
	my ($self, $json, $params, $return_struct, $out_file) = @_;
	$json = $self->decode($json) 
	unless ref $json;
	$params = $self->decode($params) unless ref $params;
	$json = $self->SUPER::compile($json, $params);
	return $return_struct 
		? $json 
		: $self->encode($json, $out_file);
}

1;

__END__

=head1 NAME

JSON::Conditional - A conditional language within a JSON struct

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use JSON::Conditional;

	my $c = JSON::Conditional->new();

	my $json = '{
		"for": {
			"key": "countries",
			"each": "countries",
			"if": {
				"m": "Thailand",
				"key": "country",
				"then": {
					"rank": 1
				}
			},
			"elsif": {
				"m": "Indonesia",
				"key": "country",
				"then": {
					"rank": 2
				}
			},
			"else": {
				"then": {
					"rank": null
				}
			},
			"country": "{country}"
		}
	}';

	$json = $c->compile($json, {
		countries => [
			{ country => "Thailand" },
			{ country => "Indonesia" },
			{ country => "Japan" },
			{ country => "Cambodia" },
		]
	});

	...

	{
		"countries": [
			{
				"rank": 1,
				"country": "Thailand"
			},
			{
				"rank": 2,
				"country": "Indonesia"
			},
			{
				"rank": null,
				"country": "Japan"
			},
			{
				"rank": null,
				"country": "Cambodia"
			}
		]
	};

=head1 METHODS

=head2 new

Instantiate a new JSON::Conditional object. Currently this expects no arguments.

	my $c = JSON::Conditional->new;

=head2 encode

Encode a perl struct into JSON.

	$c->encode($struct);

=head2 encode_file

Encode a perl struct into JSON file.

	$c->encode_file($struct, $out_file);

=head2 decode

Decode a JSON string into a perl struct.

	$c->decode($json);

=head2 decode_file

Decode a JSON file into a perl struct.

	$c->decode_file($json_file);

=head2 compile

Compile a json string or file containing valid JSON::Conditional markup into either a json string, json file or perl struct based upon the passed params.

	$c->compile($json, $params); # json string

	$c->compile($json, $params, 1); # perl struct

	$c->compile($json, $params, 0, $out_file); # json file

=head1 Markup or Markdown

=head2 keywords

=head3 if, elsif, else

If, elsif and else conditionals are logical blocks used within JSON::Conditional. They are comprised of a minimum of four parts, the keyword, the expression, 'key' and 'then'. The expression can be any that are defined in the expression section of this document. The 'key' is the value in the params that will be evaluated and the 'then' is the response that is returned if the expression is true.

	my $json = '{
		"if": {
			"m": "Thailand",
			"key": "country",
			"then": {
				"rank": 1
			}
		},
		"elsif": {
			"m": "Indonesia",
			"key": "country",
			"then": {
				"rank": 2
			}
		},
		"else": {
			"then": {
				"rank": null
			}
		},
		"country": "{country}"
	}';

	$json = $c->compile($json, {
		country => "Thailand"
	}, 1);

	...

	{
		country => 'Thailand',
		rank => 1
	}

You can also write this like the following:

	my $json = '{
		"if": {
			"m": "Thailand",
			"key": "country",
			"then": {
				"rank": 1
			},
			"elsif": {
				"m": "Indonesia",
				"key": "country",
				"then": {
					"rank": 2
				},
				"else": {
					"then": {
						"rank": null
					}
				}
			}
		},
		"country": "{country}"
	}';

	$json = $c->compile($json, {
		country => "Indonesia"
	}, 1);

	...

	{
		country => 'Indonesia',
		rank => 2
	}

=head3 given

Given conditionals are logical blocks used within JSON::Conditional. They are comprised of a minimum of three parts, the keyword, 'when' and'key'. The 'when' can either be an array or a hash of expression that are defined in the expression section of this document. The 'key' is the value in the params that will be evaluated. You can optionally provide a default which will be used when no 'when' expressions are matched.

	my $json = '{
		"given": {
			"key": "country",
			"default": {
				"rank": null
			},
			"when": [
				{
					"m": "Thailand",
					"then": {
						"rank": 1
					}
				},
				{
					"m": "Indonesia",
					"then": {
						"rank": 2
					}
				}
			]
		},
		"country": "{country}"
	}';

	my $compiled = $c->compile($json, {
		country => 'Thailand'
	}, 1);

	...

	{
		country => 'Thailand'
		rank => 1
	}

You can also write this like the following:

	my $json = '{
		"given": {
			"key": "country",
			"when": {
				"Thailand": {
					"rank": 1
				},
				"Indonesia": {
					"rank": 2
				},
				"default": {
					"rank": null
				}
			}
		},
		"country": "{country}"
	}';

	my $compiled = $c->compile($json, {
		country => 'Indonesia'
	}, 1);

	...

	{
		country => 'Indonesia'
		rank => 1
	}

=head3 or

The 'or' keyword allows you to chain expression checks, where only one expression has to match.

	my $json = '{
		"if": {
			"m": "Thailand",
			"key": "country",
			"then": {
				"rank": 1,
				"country": "{country}"
			},
			"or": {
				"key": "country",
				"m": "Maldives",
				"or": {
					"key": "country",
					"m": "Greece"
				}
			}
		},
	}';


	my $compiled = $c->compile($json, {
		country => 'Greece'
	}, 1);

	...

	{
		country => 'Greece'
		rank => 1
	}

=head3 and

The 'and' keyword allows you to chain expression checks, where only all expression has to match.

	my $json = '{
		"if": {
			"m": "Thailand",
			"key": "country",
			"then": {
				"rank": 1,
				"country": "{country}"
			},
			"and": {
				"key": "season",
				"m": "Summer"
			}
		}
	}';

	my $compiled = $c->compile($json, {
		country => 'Thailand',
		season => 'Summer'
	}, 1);

	...

	{
		country => 'Thailand'
		rank => 1
	}


=head2 expressions

=head3 m

Does the params key value match the provided regex value.

	{
		"key": $param_key,
		"m": $regex,
		"then": \%then
	}

=head3 im

Does the params key value match the provided regex value case insensative.

	{
		"key": $param_key,
		"im": $regex,
		"then": \%then
	}

=head3 nm

Does the params key value not match the provided regex value.

	{
		"key": $param_key,
		"nm": $regex,
		"then": \%then
	}

=head3 inm

Does the params key value not match the provided regex value case insensative.

	{
		"key": $param_key,
		"inm": $regex,
		"then": \%then
	}

=head3 eq

Does the params key value equal the provided value.

	{
		"key": $param_key,
		"eq": $equals,
		"then": \%then
	}

=head3 ne

Does the params key value not equal the provided value.

	{
		"key": $param_key,
		"ne": $equals,
		"then": \%then
	}

=head3 gt

Is the params key value greater than the provided value.

	{
		"key": $param_key,
		"gt": $greater_than,
		"then": \%then
	}

=head3 lt

Is the params key value less than the provided value.

	{
		"key": $param_key,
		"lt": $greater_than,
		"then": \%then
	}

=head2 placeholders

All parameters that are passed into compile can be used as placeholders within the json. You can define a placeholder by enclosing a key in braces.

	{
		"placeholder": "{param_key}"
	}

=head2 loops

=head3 for

=head4 each

Expects key to reference a array in the passed params. It will then itterate each item in the array and build an array based upon which conditions/expressions are met.

	my $json = '{
		"for": {
			"key": "countries",
			"each": "countries",
			"country": "{country}"
		}
	}';

	$json = $c->compile($json, {
		countries => [
			{ country => "Thailand" },
			{ country => "Indonesia" },
			{ country => "Japan" },
			{ country => "Cambodia" },
		]
	}, 1);

	...

	{
		countries => [
			{
				country => "Thailand"
			},
			{
				country => "Indonesia"
			},
			{
				country => "Japan",
			},
			{
				country => "Cambodia"
			}
		]
	};

=head4 keys

Expects key to reference a hash in the passed params. It will then itterate keys in the hash and build an hash based upon which conditions/expressions are met.

	my $json = '{
		"for": {
			"key": "countries",
			"keys": 1,
			"country": "{country}"
		},
	}';

	$json = $c->compile($json, {
		countries => {
			1 => { country => "Thailand" },
			2 => { country => "Indonesia" },
			3 => { country => "Japan" },
			4 => { country => "Cambodia" },
		}
	}, 1);

	...

	{
		1 => { country => "Thailand" },
		2 => { country => "Indonesia" },
		3 => { country => "Japan" },
		4 => { country => "Cambodia" },
	}

	===================================================

	my $json = '{
		"for": {
			"key": "countries",
			"keys": "countries",
			"country": "{country}"
		},
	}';

	$json = $c->compile($json, {
		countries => {
			1 => { country => "Thailand" },
			2 => { country => "Indonesia" },
			3 => { country => "Japan" },
			4 => { country => "Cambodia" },
		}
	}, 1);

	...

	{
		countries => {
			1 => { country => "Thailand" },
			2 => { country => "Indonesia" },
			3 => { country => "Japan" },
			4 => { country => "Cambodia" },
		}
	}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-json-conditional at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSON-Conditional>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc JSON::Conditional

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=JSON-Conditional>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/JSON-Conditional>

=item * Search CPAN

L<https://metacpan.org/release/JSON-Conditional>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of JSON::Conditional

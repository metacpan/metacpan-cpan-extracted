package JSON::Hyper;

use 5.008;
use strict;

use JSON::Hyper::Link;

use Carp;
use JSON;
use JSON::Path;
use LWP::UserAgent;
use Scalar::Util qw[blessed];
use Storable qw[dclone];
use URI;
use URI::Escape qw[uri_unescape];

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.011';
our $DEBUG     = 0;

sub json_ref
{
	return {
		description => 'A hyper schema for the JSON referencing convention',
		links       => [
			{
				href => '{id}',
				link => 'self',
			},
			{
				href => '{$ref}',
				link => 'full',
			},
			{
				href => '{$schema}',
				link => 'describedby',
			},
		],
		fragmentResolution   => 'dot-delimited',
		additionalProperties => { '$ref' => '#' },
	};
}

sub new
{
	my ($class, $schema) = @_;
	$schema ||= json_ref();
	$schema = from_json($schema) unless ref $schema;
	return bless { schema => $schema, ua => undef } => $class;
}

sub schema
{
	my ($self) = @_;
	return $self->{'schema'};
}

sub ua
{
	my $self = shift;
	$self = {} unless blessed($self);
	
	if (@_)
	{
		my $rv = $self->{'ua'};
		$self->{'ua'} = shift;
		croak "Set UA to something that is not an LWP::UserAgent!"
			unless blessed $self->{'ua'} && $self->{'ua'}->isa('LWP::UserAgent');
		return $rv;
	}
	unless (blessed $self->{'ua'} and $self->{'ua'}->isa('LWP::UserAgent'))
	{
		$self->{'ua'} = 'LWP::UserAgent'->new(
			agent=>sprintf('%s/%s ', __PACKAGE__, $VERSION)
		);
		$self->{'ua'}->default_header(
			'Accept'=>'application/json, application/schema+json',
		);
	}
	return $self->{'ua'};
}

sub find_links
{
	my ($self, $node, $base) = @_;
	
	$node = from_json($node) unless ref $node;
	return unless ref $node eq 'HASH';
	my @rv;
	
	foreach my $link (@{ $self->schema->{links} })
	{
		my $missing = 0;
		my $href = $link->{href};
		$href =~ s/\{(.+?)\}/if (exists $node->{$1}) { $node->{$1}; } else { $missing++; ''; }/gex;
		
		if (!$missing)
		{
			$href = $self->_resolve_relative_ref($href, $base) if defined $base;
			
			push @rv, 'JSON::Hyper::Link'->new({
				href         => $href,
				rel          => ($link->{'rel'} || $link->{'link'}),
				targetSchema => $link->{'targetSchema'},
				method       => $link->{'method'},
				enctype      => $link->{'enctype'},
				schema       => $link->{'schema'},
				properties   => $link->{'properties'},
			});
		}
	}
	
	return @rv;
}

sub _resolve_relative_ref
{
	my ($self, $ref, $base) = @_;

	return $ref unless $base; # keep relative unless we have a base URI

	if ($ref =~ /^([a-z][a-z0-9\+\.\-]*)\:/i)
	{
		return $ref; # already an absolute reference
	}

	# create absolute URI
	my $abs = URI->new_abs($ref, $base)->canonical->as_string;

	while ($abs =~ m!^(http://.*)(\.\./|\.)+(\.\.|\.)?$!i)
		{ $abs = $1; } # fix edge case of 'http://example.com/../../../'

	return $abs;
}

sub process_includes
{
	my ($self, $original, $base, $recurse) = @_;
	$original = from_json($original) unless ref $original;
	$self->_process_includes($original, $base, $recurse);
	return $original;
}

sub _process_includes
{
	my ($self, $object, $base, $recurse) = @_;
	
	my @links = $self->find_links($object, $base);
	my $full;
	foreach my $link (@links)
	{
		if (lc $link->{rel} eq 'full')
		{
			$full = $link;
			last;
		}
	}
	
	if (defined $full)
	{
		my ($substitute) = $self->get($full->{'href'});
		if (defined $substitute)
		{
			delete $object->{ $full->{'property'} };
			while (my($k,$v) = each %$substitute)
			{
				$object->{$k} = $v;
			}
		}
		return;
	}
	return unless $recurse;

	if (ref $object eq 'ARRAY')
	{
		foreach my $i (@$object)
		{
			$self->_process_includes($i, $base, $recurse);
		}
	}
	elsif (ref $object eq 'HASH')
	{
		foreach my $i (values %$object)
		{
			$self->_process_includes($i, $base, $recurse);
		}
	}
}

sub get
{
	my ($self, $uri) = @_;
	my ($resource, $fragment) = split /\#/, $uri, 2;
	my $object = $self->_get($resource);
	return $object unless $fragment;
	return $self->resolve_fragment($object, $fragment);
}

sub _get
{
	my ($self, $resource) = @_;
	
	warn "GETting $resource" if $DEBUG;
	
	unless ($self->{'cache'}->{$resource})
	{
		my $response = $self->ua->get($resource);
		return unless $response->is_success;
		$self->{'cache'}->{$resource} = from_json( $response->decoded_content );
		$self->{'http_cache'}->{$resource} = $resource;
	}
	
	my @r = ($self->{'cache'}->{$resource}, $self->{'http_cache'}->{$resource});
	return wantarray ? @r : $r[0];
}

sub resolve_fragment
{
	my ($self, $object, $fragment) = @_;
	my $style = $self->schema->{fragmentResolution} || 'slash-delimited';

	$object = from_json($object) unless ref $object;
	return $object unless $fragment;

	$fragment =~ s!^#!!;

	if ($style =~ /^(json.?)?path$/i)
	{
		my $jsonp   = JSON::Path->new(uri_unescape($fragment));
		my @matches = $jsonp->values($object);
		return @matches;
	}
	elsif (lc $style eq 'dot-delimited')
	{
		$fragment =~ s!^\.!!;
	}
	elsif (lc $style eq 'slash-delimited')
	{
		$fragment =~ s!^/!!;
	}
	else
	{
		carp "Unknown fragment resolution method: $style";
		return;
	}
	
	return $self->_resolve_fragment($object, $fragment);
}

sub _resolve_fragment
{
	my ($self, $object, $fragment) = @_;
	my $style = $self->schema->{fragmentResolution} || 'slash-delimited';
	
	my ($first, $rest);
	if (lc $style eq 'dot-delimited')
	{
		($first, $rest) = split /\./, $fragment, 2;
	}
	elsif (lc $style eq 'slash-delimited')
	{
		($first, $rest) = split /\//, $fragment, 2;
	}

	$first = uri_unescape($first);

	my $value;
	if (ref $object eq 'HASH')
	{
		$value = $object->{$first};
	}
	elsif (ref $object eq 'ARRAY' and $first =~ /^[\-\+]?[0-9]+$/)
	{
		$value = $object->[$first];
	}
	
	unless (defined $value)
	{
		return;
	}
	
	if (length $rest)
	{
		return $self->_resolve_fragment($value, $rest);
	}
	else
	{
		return ($value);
	}
}

1;

__END__

=head1 NAME

JSON::Hyper - extract links from JSON via a schema

=head1 SYNOPSIS

 my $hyper = JSON::Hyper->new($hyperschema);
 my $json  = from_json( ... );
 my @links = $hyper->find_links($json->[1]->{some}->{object});
 foreach my $link (@links)
 {
   printf("<%s> (%s)", $link->{href}, $link->{rel});
 }

=head1 DESCRIPTION

The JSON Hyper Schema proposal defines hypertext navigation through data
structures represented by JSON.

=head2 Constructor

=over 4

=item C<< new($hyperschema) >>

Given a JSON (or equivalent Perl nested hashref/arrayref structure)
Hyper Schema, returns a Perl object capable of interpreting that schema.

If the schema is omitted, defaults to the JSON Referencing hyper
schema (described at L<http://json-schema.org/json-ref>)

=back

=head2 Methods

=over 4

=item C<< schema >>

Returns the original schema as a hashref/arrayref structure.

=item C<< ua >>

Get/set the LWP::UserAgent instance used to retrieve things.

=item C<< find_links($object, $base) >>

Given a JSON object (or equivalent Perl nested hashref/arrayref structure)
and optionally a base URL for interpreting relative URI references, returns
a list of links found on object node. Does not operate recursively.

Each link is a L<JSON::Hyper::Link> object.

=item C<< get($uri) >>

Performs an HTTP request for the given URI and returns a list of Perl
nested hashref/arrayref structures corresponding to the JSON response.
The URI may contain a fragment identifier, which will be interpreted
according to the schema's fragment resolution method. Fragment
resolution methods supported include:

=over 8

=item * slash-delimited (default)

=item * dot-delimited

=item * jsonpath

=back

For example, assuming the hyper schema specifies slash-delimited
fragments, the following:

 my $hyper    = JSON::Hyper->new($hyperschema);
 my ($result) = $hyper->get('http://example.com/data.json#foo/bar/0');

Is roughly equivalent to:

 use JSON;
 use LWP::UserAgent;
 my $ua       = LWP::UserAgent->new;
 my $response = $ua->get('http://example.com/data.json');
 my $object   = from_json($response->decoded_content);
 my $result   = $object->{foo}{bar}[0];

Note, if called multiple times on the same URL will return not just
equivalent objects, but the same object.

So, why does this method return a list of results instead of just
a single result? In most cases, there will be either 0 or 1 items
on the list; however, JSONPath allows a path to match multiple
nodes, so there will occasionally be more than one result. (In 
scalar context, this method just returns the first result anyway.)

=item C<< resolve_fragment($object, $fragment) >>

Used by C<get> to resolve the fragment part of a URL against an object.

=item C<< process_includes($object, $base, $recurse) >>

Given an JSON object (or equivalent Perl nested hashref/arrayref
structure) and optional base URL, crawls the object finding
rel="full" links, dereferences them using C<get> and replaces
the appropriate nodes with the retrieved content. $recurse
is a boolean.

This has the effect of rel="full" behaving like inclusion does
in various programming languages.

This modifies the given object rather than creating a new object.

=back

=head2 Utilities

=over

=item C<< JSON::Hyper::json_ref() >>

Returns the JSON referencing hyperschema as a hashref.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<JSON::Hyper::Link>.

Related modules: L<JSON::T>, L<JSON::Path>, L<JSON::GRDDL>,
L<JSON::Schema>.

L<http://tools.ietf.org/html/draft-zyp-json-schema>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2010-2012 Toby Inkster.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=head2 a.k.a. "The MIT Licence"

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut

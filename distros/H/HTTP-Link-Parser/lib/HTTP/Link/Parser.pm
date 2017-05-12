package HTTP::Link::Parser;

use 5.010;
use strict;
no warnings;

BEGIN
{
	$HTTP::Link::Parser::AUTHORITY = 'cpan:TOBYINK';
	$HTTP::Link::Parser::VERSION   = '0.200';
	
	require Exporter;
	our @ISA = qw(Exporter);
	our %EXPORT_TAGS = (
		'all'      => [qw/parse_links_into_model parse_links_to_rdfjson parse_links_to_list parse_single_link relationship_uri/],
		'standard' => [qw/parse_links_into_model parse_links_to_rdfjson/],
	);
	our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
	our @EXPORT    = @{ $EXPORT_TAGS{'standard'} };
}

use Carp qw(croak carp);
use Encode qw(decode encode_utf8);
use Scalar::Util qw(blessed);
use URI;
use URI::Escape;

use constant (
	LINK_NAMESPACE => 'http://www.iana.org/assignments/relation/',
);

sub parse_links_into_model
{
	my ($response, $model) = @_;
	
	croak "Parameter to parse_links_into_model should be an HTTP::Message"
		unless blessed($response) && $response->isa('HTTP::Message');
	
	require RDF::Trine;
	
	my $model ||= RDF::Trine::Model->temporary_model;
	$model->add_hashref(parse_links_to_rdfjson($response));
	return $model;
}

sub parse_links_to_rdfjson
{
	my ($response) = @_;
	
	croak "Parameter to parse_links_to_rdfjson should be an HTTP::Message."
		unless blessed($response) && $response->isa('HTTP::Message');
		
	my $base  = URI->new($response->base);
	my $links = parse_links_to_list($response);
	my $rv    = {};
	
	foreach my $link (@$links)
	{
		my $subject = $base;
		
		$subject = $link->{'anchor'}
			if defined $link->{'anchor'};
		
		my $object = $link->{'URI'};
		
		foreach my $r (@{ $link->{'rel'} })
		{
			my $r1 = relationship_uri($r);
			push @{ $rv->{ $subject }->{ $r1 } },
				{
					'value'    => "$object",
					'type'     => 'uri',
				};
		}
		
		foreach my $r (@{ $link->{'rev'} })
		{
			my $r1 = relationship_uri($r);
			push @{ $rv->{ $object }->{ $r1 } },
				{
					'value'    => "$subject",
					'type'     => 'uri',
				};
		}
		
		if (defined $link->{'title'})
		{
			if (blessed($link->{'title'}) && $link->{'title'}->isa('HTTP::Link::Parser::PlainLiteral'))
			{
				push @{ $rv->{ $object }->{ 'http://purl.org/dc/terms/title' } },
					{
						'value'    => encode_utf8($link->{'title'}.''),
						'type'     => 'literal',
						'lang'     => $link->{'title'}->lang,
					};
			}
			else
			{
				push @{ $rv->{ $object }->{ 'http://purl.org/dc/terms/title' } },
					{
						'value'    => $link->{'title'},
						'type'     => 'literal',
					};
			}
		}
		
		if (defined $link->{'title*'})
		{
			foreach my $t (@{ $link->{'title*'} })
			{
				push @{ $rv->{ $object }->{ 'http://purl.org/dc/terms/title' } },
					{
						'value'    => encode_utf8("$t"),
						'type'     => 'literal',
						'lang'     => $t->lang,
					};
			}
		}
		
		if (defined $link->{'hreflang'})
		{
			foreach my $lang (@{ $link->{'hreflang'} })
			{
				push @{ $rv->{ $object }->{ 'http://purl.org/dc/terms/language' } },
					{
						'value'    => 'http://www.lingvoj.org/lingvo/' . uri_escape(lc $lang),
						'type'     => 'uri',
					};
			}
		}
		
		if (defined $link->{'type'} && $link->{'type'} =~ m?([A-Z0-9\!\#\$\&\.\+\-\^\_]{1,127})/([A-Z0-9\!\#\$\&\.\+\-\^\_]{1,127})?i)
		{
			my $type    = lc $1;
			my $subtype = lc $2;
			push @{ $rv->{ $object }->{ 'http://purl.org/dc/terms/format' } },
				{
					'value'    => 'http://www.iana.org/assignments/media-types/'.uri_escape($type).'/'.uri_escape($subtype),
					'type'     => 'uri',
				};
		}
	}
	
	return $rv;
}

sub relationship_uri
{
	my ($str) = @_;
	
	if ($str =~ /^([a-z][a-z0-9\+\.\-]{0,126})\:/i)
	{
		# seems to be an absolute URI, so can safely return "as is".
		return $str;
	}
	
	return LINK_NAMESPACE . lc $str;
}

sub parse_links_to_list
{
	my ($response) = @_;
	
	croak "Parameter to parse_links_to_list should be an HTTP::Message."
		unless blessed($response) && $response->isa('HTTP::Message');
	
	my $rv   = [];
	my $base = URI->new($response->base);
	
	my $clang;
	if ($response->header('Content-Language') =~ /^\s*([^,\s]+)/)
	{
		$clang = $1;
	}
	
	foreach my $header ($response->header('Link'))
	{
		push @$rv, parse_single_link($header, $base, $clang);
	}
	
	return $rv;
}

sub parse_single_link
{
	my ($hdrv, $base, $default_lang) = @_;
	my $rv   = {};
	
	my $uri  = undef;
	if ($hdrv =~ /^(\s*<([^>]*)>\s*)/)
	{
		$uri  = $2;
		$hdrv = substr($hdrv, length($1));
	}
	else
	{
		return $rv;
	}
	
	$rv->{'URI'} = URI->new_abs($uri, $base);
	
	while ($hdrv =~ /^(\s*\;\s*(\/|[a-z0-9-]+\*?)\s*\=\s*("[^"]*"|[^\s\"\;\,]+)\s*)/i)
	{
		$hdrv = substr($hdrv, length($1));
		my $key = lc $2;
		my $val = $3;
		
		$val =~ s/(^"|"$)//g if ($val =~ /^".*"$/);
		
		if ($key eq 'rel')
		{
			$val =~ s/(^\s+)|(\s+$)//g;
			$val =~ s/\s+/ /g;
			
			my @rels = split / /, $val;
			foreach my $rel (@rels)
				{ push @{ $rv->{'rel'} }, $rel; }
		}
		elsif ($key eq 'rev')
		{
			$val =~ s/(^\s+)|(\s+$)//g;
			$val =~ s/\s+/ /g;
			
			my @rels = split / /, $val;
			foreach my $rel (@rels)
				{ push @{ $rv->{'rev'} }, $rel; }
		}
		elsif ($key eq 'anchor')
		{
			$rv->{'anchor'} = URI->new_abs($val, $base)
				unless defined $rv->{'anchor'};
		}
		elsif ($key eq 'title')
		{
			if (defined $default_lang)
			{
				my $lit = bless [$val, undef, lc $default_lang], 'HTTP::Link::Parser::PlainLiteral';
				push @{ $rv->{'title'} }, $lit;
			}
			else
			{
				$rv->{'title'} = $val
					unless defined $rv->{'title'};
			}
		}
		elsif ($key eq 'title*')
		{
			my ($charset, $lang, $string) = split /\'/, $val;
			$string = uri_unescape($string);
			$string = decode($charset, $string);
			my $lit = bless [$string, undef, lc $lang], 'HTTP::Link::Parser::PlainLiteral';
			push @{ $rv->{'title*'} }, $lit;
		}
		elsif ($key eq 'type')
		{
			$rv->{'type'} = $val
				unless defined $rv->{'type'};
		}
		else # hreflang, plus any extended types.
		{
			push @{ $rv->{ $key } }, $val;
		}
	}
	
	return $rv;
}

{
	package HTTP::Link::Parser::PlainLiteral;
	
	use overload
		'""' => sub { $_[0]->[0] },
		'eq' => sub { $_[0]->[0] eq $_[1]->[0] and lc $_[0]->[2] eq lc $_[1]->[2] };
	
	sub value { $_[0]->[0]; }
	sub lang { length $_[0]->[2] ? $_[0]->[2] : undef; }
}

1;

__END__

=pod

=encoding utf-8

=for stopwords hreflang prev rel

=head1 NAME

HTTP::Link::Parser - parse HTTP Link headers

=head1 SYNOPSIS

  use HTTP::Link::Parser ':standard';
  use LWP::UserAgent;
  
  my $ua = LWP::UserAgent->new;
  my $response = $ua->get("http://example.com/foo");
  
  # Parse link headers into an RDF::Trine::Model.
  my $model = parse_links_into_model($response);

  # Find data about <http://example.com/foo>.
  my $iterator = $model->get_statements(
    RDF::Trine::Node::Resource->new('http://example.com/foo'),
    undef,
    undef);

  while ($statement = $iterator->next)
  {
     # Skip data where the value is not a resource (i.e. link)
     next unless $statement->object->is_resource;

     printf("Link to <%s> with rel=\"%s\".\n",
        $statement->object->uri,
        $statement->predicate->uri);
  }

=head1 DESCRIPTION

HTTP::Link::Parser parses HTTP "Link" headers found in an
HTTP::Response object. Headers should conform to the format
described in RFC 5988.

=head2 Functions

To export all functions:

  use HTTP::Link::Parser ':all';

=over 4

=item C<< parse_links_into_model($response, [$existing_model]) >>

Takes an L<HTTP::Response> object (or in fact, any L<HTTP::Message> object)
and returns an L<RDF::Trine::Model> containing link data extracted from the
response. Dublin Core is used to encode 'hreflang', 'title' and 'type' link
parameters.

C<$existing_model> is an RDF::Trine::Model to add data to. If omitted, a
new, empty model is created.

=item C<< parse_links_to_rdfjson($response) >>

Returns a hashref with a structure inspired by the RDF/JSON
specification. This can be thought of as a shortcut for:

  parse_links_into_model($response)->as_hashref

But it's faster as no intermediate model is built.

=item C<< relationship_uri($short) >>

This function is not exported by default. 

It may be used to convert short strings identifying relationships,
such as "next" and "prev", into longer URIs identifying the same
relationships, such as "http://www.iana.org/assignments/relation/next"
and "http://www.iana.org/assignments/relation/prev".

If passed a string which is a URI already, simply returns it as-is.

=back

=head2 Internal Functions

These are really just internal implementations, but you can use them if you
like.

=over

=item C<< parse_links_to_list($response) >>

This function is not exported by default. 

Returns an arrayref of hashrefs. Each hashref contains keys
corresponding to the link parameters of the link, and a key called
'URI' corresponding to the target of the link.

The 'rel' and 'rev' keys are arrayrefs containing lists of
relationships. If the Link used the short form of a registered
relationship, then the short form is present on this list. Short
forms can be converted to long forms (URIs) using the
C<relationship_uri> function.

The structure returned by this function should not be considered
stable.

=item C<< parse_single_link($link, $base, [$default_lang]) >>

This function is not exported by default. 

This parses a single Link header (minus the "Link:" bit itself) into a hashref
structure. A base URI must be included in case the link contains relative URIs.
A default language can be provided for the 'title' parameter.

The structure returned by this function should not be considered stable.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<http://www.ietf.org/rfc/rfc5988.txt>.

L<RDF::Trine>,
L<HTTP::Response>,
L<XRD::Parser>,
L<HTTP::LRDD>.

L<http://n2.talis.com/wiki/RDF_JSON_Specification>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2009-2011, 2014 by Toby Inkster

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


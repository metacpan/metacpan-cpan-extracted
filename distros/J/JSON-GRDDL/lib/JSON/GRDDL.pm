use 5.010;
use strict;
use warnings;

package JSON::GRDDL;

use Carp;
use JSON;
use JSON::T;
use LWP::UserAgent;
use Object::AUTHORITY;
use RDF::Trine;
use Scalar::Util qw[blessed];

BEGIN {
	$JSON::GRDDL::AUTHORITY = 'cpan:TOBYINK';
	$JSON::GRDDL::VERSION   = '0.002';
}

sub new
{
	my ($class) = @_;
	return bless { cache=>{}, ua=>undef, }, $class;
}

sub ua
{
	my $self = shift;
	if (@_)
	{
		my $rv = $self->{'ua'};
		$self->{'ua'} = shift;
		croak "Set UA to something that is not an LWP::UserAgent!"
			unless blessed $self->{'ua'} && $self->{'ua'}->isa('LWP::UserAgent');
		return $rv;
	}
	unless (blessed $self->{'ua'} && $self->{'ua'}->isa('LWP::UserAgent'))
	{
		$self->{'ua'} = LWP::UserAgent->new(agent=>sprintf('%s/%s (%s) ',
			__PACKAGE__,
			__PACKAGE__->VERSION,
			__PACKAGE__->AUTHORITY,
			));
	}
	return $self->{'ua'};
}

sub data
{
	my ($self, $document, $uri, %options) = @_;
	
	unless (ref $document)
	{
		$document = from_json("$document");
	}
	
	$options{'model'} ||= RDF::Trine::Model->temporary_model;
	
	my $T = $self->discover($document, $uri, %options);
	if ($T)
	{
		return $self->transform_by_uri($document, $uri, $T, %options);
	}
	elsif (ref $document eq 'HASH' and !$options{'nested'}
	  and  (not grep { $_ !~ /:/ } keys %$document))
	{
		# looks like it's bona-fide RDF/JSON.
		$options{'model'}->add_hashref($document);
		return $options{'model'};
	}
	elsif (ref $document eq 'HASH'
	  and  $document->{'$schema'}->{'$ref'} eq 'http://soapjr.org/schemas/RDF_JSON')
	{
		# claims it's bona-fide RDF/JSON.
		$options{'model'}->add_hashref($document);
		return $options{'model'};
	}
	
	# Not returned anything yet, so try recursing.
	{
		local $options{'nested'} = 1;
		
		if (ref $document eq 'HASH')
		{
			foreach my $item (values %$document)
			{
				if ('HASH' eq ref $item or 'ARRAY' eq ref $item)
				{
					$self->data($item, $uri, %options);
				}
			}
		}
		elsif (ref $document eq 'ARRAY')
		{
			foreach my $item (@$document)
			{
				if ('HASH' eq ref $item or 'ARRAY' eq ref $item)
				{
					$self->data($item, $uri, %options);
				}
			}
		}
	}
	
	return $options{'model'};
}

sub discover
{
	my ($self, $document, $uri, %options) = @_;
	my $T;
	
	unless (ref $document)
	{
		$document = from_json("$document");
	}

	return unless ref $document eq 'HASH';
	
	if (defined $document->{'$transformation'})
	{
		$T = $self->_resolve_relative_ref($document->{'$transformation'}, $uri);
	}
	elsif (defined $document->{'$schema'}->{'$schemaTransformation'})
	{
		$T = $self->_resolve_relative_ref($document->{'$schema'}->{'$schemaTransformation'}, $uri);
	}
	elsif (defined $document->{'$schema'}->{'$ref'})
	{
		my $s = $self->_resolve_relative_ref($document->{'$schema'}->{'$ref'}, $uri);
		my $r  = $self->_fetch($s,
			Accept => 'application/schema+json, application/x-schema+json, application/json');
		
		if (defined $r
		&&  $r->code == 200
		&&  $r->header('content-type') =~ m#^\s*(((application|text)/(x-)?json)|(application/(x-)?schema\+json))\b#)
		{
			my $schema = from_json($r->decoded_content);
			if (defined $schema->{'$schemaTransformation'})
			{
				$T = $self->_resolve_relative_ref($schema->{'$schemaTransformation'}, $s);
			}
		}
	}
	return ($T);
}

sub transform_by_uri
{
	my ($self, $document, $uri, $transformation_uri, %options) = @_;
	
	my ($name) = ($transformation_uri =~ /\#(.+)$/);
	
	my $r = $self->_fetch($transformation_uri,
		Accept => 'application/ecmascript, application/javascript, text/ecmascript, text/javascript, application/x-ecmascript');
	if (defined $r
	&&  $r->code == 200
	&&  $r->header('content-type') =~ m#^\s*((application|text)/(x-)?(java|ecma)script)\b#)
	{
		return $self->transform_by_jsont($document, $uri, $r->decoded_content, $name, %options);
	}
	
	return;
}

sub transform_by_jsont
{
	my ($self, $document, $uri, $transformation, $name, %options) = @_;
	
	my $jsont = JSON::T->new($transformation, $name);
	my $out   = $jsont->transform_structure($document);
	
	_relabel($out);
	
	$options{'model'} ||= RDF::Trine::Model->temporary_model;
	$options{'model'}->add_hashref($out);
	return $options{'model'};
}

sub _relabel
{
	my ($data) = @_;
	my $pfx    = '_:p'.int( 10_000_000 + rand(80_000_000) );
	
	foreach my $key (keys %$data)
	{
		if ($key =~ /^_:(.*)/)
		{
			my $new_key = $pfx . $1;
			$data->{$new_key} = delete $data->{$key}
		}
	}
	
	foreach my $po (values %$data)
	{
		foreach my $ol (values %$po)
		{
			foreach my $o (@$ol)
			{
				next if $o->{type} =~ /literal/i;
				next if exists $o->{lang};
				next if exists $o->{datatype};
				
				if ($o->{value} =~ /^_:(.*)/)
				{
					$o->{value} = $pfx . $1;
				}				
			}
		}
	}
}

sub _fetch
{
	my ($self, $document, %headers) = @_;
	$self->{'cache'}->{$document} ||= $self->ua->get($document, %headers);
	return $self->{'cache'}->{$document};
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

1;

__END__

=head1 NAME

JSON::GRDDL - transform JSON to RDF

=head1 SYNOPSIS

 # Low-Level Interface
 #
 my $grddl = JSON::GRDDL->new;
 my @transformations = $grddl->discover($jsondoc, $baseuri);
 foreach my $trans (@transformations)
 {
   my $model = $grddl->transform_by_uri($jsondoc, $baseuri, $trans);
   # $model is an RDF::Trine::Model
 }

 # High-Level Interface
 #
 my $grddl = JSON::GRDDL->new;
 my $model = $grddl->data($jsondoc, $baseuri);
 # $model is an RDF::Trine::Model

=head1 DESCRIPTION

This module implements jsonGRDDL, a port of GRDDL concepts from XML
to JSON.

jsonGRDDL is described at L<http://buzzword.org.uk/2008/jsonGRDDL/spec>.

This module attempts to provide a similar API to L<XML::GRDDL> but differs
in some respects.

=head2 Constructor

=over 4

=item C<<  JSON::GRDDL->new  >>

The constructor accepts no parameters and returns a JSON::GRDDL
object.

=back

=head2 Methods

=over 4

=item C<< $grddl->ua >>

=item C<< $grddl->ua($ua) >>

Get/set an L<LWP::UserAgent> object for HTTP requests.

=item C<< $grddl->data($json, $base, %options) >>

This is usually what you want to call. It's a high-level method that does everything
for you and returns the RDF you wanted. $json is the raw JSON source of the
document, or an equivalent Perl hashref/arrayref structure. $base is the base
URI for resolving relative references.

Returns an RDF::Trine::Model.

=item C<< $grddl->discover($json, $base, %options) >>

You only need to call this method if you're doing something unusual.

Processes the JSON document to discover the transformation associated
with it. $json is the raw JSON source of the document, or an equivalent
Perl hashref/arrayref structure. $base is the base URI for resolving relative
references.

Returns a list of URLs as strings.

=item C<< $grddl->transform_by_uri($json, $base, $transformation, %options) >>

You only need to call this method if you're doing something unusual.

Transforms a JSON document into RDF using a JsonT transformation, specified by
URI. $json is the raw JSON source of the document, or an equivalent
Perl hashref/arrayref structure. $base is the base URI for resolving relative
references. $transformation is the URI for the JsonT transformation.

Returns an RDF::Trine::Model.

=item C<< $grddl->transform_by_jsont($json, $base, $code, $name, %options) >>

You only need to call this method if you're doing something unusual.

Transforms a JSON document into RDF using a JsonT transformation, specified
as a Javascript code, variable name pair. $json is the raw JSON source of the
document, or an equivalent Perl hashref/arrayref structure. $base is the base
URI for resolving relative references. $code and $name must be suitable for
passing to the C<new> constructor from the L<JSON::T> package.

Returns an RDF::Trine::Model.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

Specification: L<http://buzzword.org.uk/2008/jsonGRDDL/spec>.

Related modules: L<JSON>, L<JSON::T>, L<JSON::Path>,
L<JSON::Hyper>, L<JSON::Schema>, L<XML::GRDDL>.

L<http://www.perlrdf.org/>.

This module is derived from Swignition L<http://buzzword.org.uk/swignition/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2011 Toby Inkster.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


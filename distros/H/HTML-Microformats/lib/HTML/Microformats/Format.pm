=head1 NAME

HTML::Microformats::Format - base microformat class

=head1 DESCRIPTION

HTML::Microformats::Format cannot be instantiated directly but many other classes
inherit from it. 

=cut

package HTML::Microformats::Format;

use base qw(HTML::Microformats::Mixin::RDF);
use strict qw(subs vars); no warnings;
use 5.010;

use Carp;
use HTML::Microformats::Utilities qw(searchClass searchRel searchRev);
use RDF::Trine;
use Scalar::Util qw[];

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::VERSION   = '0.105';
}
our $AUTOLOAD;

# Derived classes...
#   MUST override: new
#   SHOULD override: format_signature, add_to_model, profiles
#   MIGHT WANT TO override: id, extract_all, data

=head2 Constructors

The constructors cannot actually be called on this package. Call them on descendent
classes instead.

=over 4

=item C<< $object = HTML::Microformats::Format->new($element, $context, %options) >>

Parse a microformat with root element $element. 

=cut

sub new
{
	die "Cannot instantiate HTML::Microformats::Format.\n";
}

=item C<< $object = HTML::Microformats::Format->extract_all($element, $context, %options) >>

Find and parse all such microformats within element $element. 

=back

=cut

sub extract_all
{
	my ($class, $dom, $context, %options) = @_;
	my @rv;
	
	my $hclass = $class->format_signature->{'root'};
	my $rel    = $class->format_signature->{'rel'};
	my $rev    = $class->format_signature->{'rev'};
	
	unless (defined $rel || defined $rev || defined $hclass)
	{
		die "extract_all failed.\n";
	}
	
	if (defined $hclass)
	{
		$hclass = [$hclass] unless ref $hclass eq 'ARRAY';
		
		foreach my $hc (@$hclass)
		{
			my @elements = searchClass($hc, $dom);
			foreach my $e (@elements)
			{
				my $object = $class->new($e, $context, %options);
				next unless $object;
				next if grep { $_->id eq $object->id } @rv; # avoid duplicates
				push @rv, $object if ref $object;
			}
		}
	}
	
	if (defined $rel)
	{
		$rel = [$rel] unless ref $rel eq 'ARRAY';
		
		foreach my $r (@$rel)
		{
			my @elements = searchRel($r, $dom);
			foreach my $e (@elements)
			{
				my $object = $class->new($e, $context, %options);
				next unless $object;
				next if grep { $_->id eq $object->id } @rv; # avoid duplicates
				push @rv, $object if ref $object;
			}
		}
	}
	
	if (defined $rev)
	{
		$rev = [$rev] unless ref $rev eq 'ARRAY';
		
		foreach my $r (@$rev)
		{
			my @elements = searchRev($r, $dom);
			foreach my $e (@elements)
			{
				my $object = $class->new($e, $context, %options);
				next unless $object;
				next if grep { $_->id eq $object->id } @rv; # avoid duplicates
				push @rv, $object if ref $object;
			}
		}
	}
	
	return @rv;
}

=head2 Public Methods - Accessors

There are a number of property accessor methods defined via Perl's AUTOLOAD mechanism. 

For any microformat property (e.g. 'fn' in hCard) there are get_X, set_X, add_X and
clear_X methods defined.

C<get_X>: for singular properties, returns the value of property X. For plural properties, returns a
list of values if called in list context, or the first value otherwise.

C<set_X>: for singular properties, sets the value of property X to the first given parameter.
For plural properties, sets the values of property X to the list of parameters.
B<This feature is deprecated and will be removed in a future release.>

C<add_X>: for singular properties, sets the value of property X to the first given parameter,
but croaks if X is already set. For concatenated singular properties, concatenates to the
end of any existing value of X. For plural properties, adds any given parameters to the
list of values of property X.
B<This feature is deprecated and will be removed in a future release.>

C<clear_X>: removes any values of property X, but croaks if the property is a required
property.
B<This feature is deprecated and will be removed in a future release.>

For example, an HTML::Microformats::hCard object will have a method called get_fn which
gets the value of the hCard's "fn" property, a method called set_fn which sets it, a
method called add_fn which also sets it (but croaks if it's already set), and a method
called clear_fn which croaks if called (because "fn" is a required property).

B<Deprecated features:> the C<set_X>, C<add_X> and C<clear_X> methods are 
deprecated and will be removed soon. In general you should treat objects which are
instances of HTML::Microformats::Format as read-only.

=cut

sub AUTOLOAD
{
	my $self = shift;
	my $func = $AUTOLOAD;
	
	if ($func =~ /^.*::(get|set|add|clear)_([^:]+)$/)
	{		
		my $method = $1;
		my $datum  = $2;
		my $opts   = undef;
		my $classes = $self->format_signature->{'classes'};
		
		$datum =~ s/_/\-/g;
		
		foreach my $c (@$classes)
		{
			if ($c->[0] eq $datum)
			{
				$opts = $c->[1];
				last;
			}
			elsif ($c->[2]->{'use-key'} eq $datum)
			{
				$datum = $c->[2]->{'use-key'};
				$opts  = $c->[1];
				last;
			}
		}
		
		croak "Function $func unknown.\n" unless defined $opts;
		
		if ($method eq 'get')
		{
			return $self->{'DATA'}->{$datum};
		}
		elsif ($method eq 'clear')
		{
			croak "Attempt to clear required property $datum.\n"
				if $opts =~ /[1\+]/;
			delete $self->{'DATA'}->{$datum};
		}
		elsif ($method eq 'add')
		{
			croak "Attempt to add more than one value to singular property $datum.\n"
				if $opts =~ /[1\?]/ && defined $self->{'DATA'}->{$datum};
			
			if ($opts =~ /[1\?]/)
			{
				$self->{'DATA'}->{$datum} = shift;
			}
			elsif ($opts =~ /[\&]/)
			{
				$self->{'DATA'}->{$datum} .= shift;
			}
			else
			{
				push @{ $self->{'DATA'}->{$datum} }, @_;
			}
		}
		elsif ($method eq 'set')
		{
			if ($opts =~ /[1\?\&]/)
			{
				$self->{'DATA'}->{$datum} = shift;
			}
			else
			{
				$self->{'DATA'}->{$datum} = \@_;
			}
		}
	}
	else
	{
		croak "No function '$func' defined.\n"
			unless $func =~ /::(DESTROY|no|import)$/;
	}
}

=head2 Public Methods - Other

=over 4

=item C<< $object->format_signature >> or C<< $class->format_signature >>

This method may be called as a class or object method. It returns various information
about the definition of this microformat (e.g. what is the root class, which properties
exist, etc). You may need to do some digging to figure out what everything means.

=cut

sub format_signature
{
	return {
		'root'         => undef ,
		'rel'          => undef ,
		'classes'      => [] ,
		'options'      => {} ,
		'rdf:type'     => 'http://www.w3.org/2002/07/owl#Thing' ,
		'rdf:property' => {} ,
		};
}

=item C<< $object->profiles >> or C<< $class->profiles >>

This method may be called as a class or object method. It returns HTML profile
URIs which indicate the presence of this microformat.

=cut

sub profiles
{
	return qw();
}

=item C<< $object->context >> 

Returns the parsing context (as supplied to C<new>).

=cut

sub context
{
	return $_[0]->{'context'};
}

=item C<< $object->data >> 

Returns a hashref of object data. This is a reference to the live data inside the
object. Any changes to the returned hashref will change the values inside the object.

=cut

sub data
{
	return {} unless defined $_[0]->{'DATA'};
	return $_[0]->{'DATA'};
}

sub TO_JSON
{
	return data( $_[0] );
}

=item C<< $object->element >> 

Returns the root element.

=cut

sub element
{
	return $_[0]->{'element'};
}

=item C<< $object->cache >> 

Shortcut for C<< $object->context->cache >>.

=cut

sub cache
{
	return $_[0]->{'cache'};
}

=item C<< $object->id([$trine_obj], [$role]) >> 

Returns a blank node identifier or identifying URI for the object.

If $trine_obj is true, the return value is an RDF::Trine::Node object. Otherwise,
it's a string (using the '_:' convention to identify blank nodes).

If $role is undefined, then returns the identifier for the object itself.
If it's defined then it returns an identifier for a resource with a fixed
relationship to the object.

  $identifier_for_business_card  = $hcard->id;
  $identifier_for_person         = $hcard->id(undef, 'holder');

=cut

sub id
{
	my ($self, $as_trine, $role) = @_;

	my $id = defined $role ? $self->{"id.${role}"} : $self->{'id'};
	
	unless (defined $id)
	{
		$self->{ defined $role ? "id.${role}" : 'id' } = $self->context->make_bnode;
		$id = defined $role ? $self->{"id.${role}"} : $self->{'id'};
	}

	return $id unless $as_trine;
	return ($id  =~ /^_:(.*)$/) ?
	       RDF::Trine::Node::Blank->new($1) :
	       RDF::Trine::Node::Resource->new($id);
}

=item C<< $object->add_to_model($model) >> 

Given an RDF::Trine::Model object, adds relevant data to the model.

=cut

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	return $self;
}

=item C<< $object->model >> 

Creates a fresh, new RDF::Trine::Model object, containing relevant data.

=cut

sub model
{
	my $self  = shift;
	my $model = RDF::Trine::Model->temporary_model;
	$self->add_to_model($model);
	return $model;
}

=item C<< $object->serialise_model(as => $format) >> 

As C<model> but returns a string.

=back

=cut

sub serialise_model
{
	my $self = shift;
	
	my %opts = ref $_[0] ? %{ $_[0] } : @_;
	$opts{as} ||= 'Turtle';
	
	my $ser = RDF::Trine::Serializer->new(delete $opts{as}, %opts);
	return $ser->serialize_model_to_string($self->model);
}

sub _isa # utility function for subclasses to use
{
	return Scalar::Util::blessed($_[1]) && $_[1]->isa($_[2]);
}

1;

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut



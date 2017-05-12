package HTML::Microformats::Mixin::RDF;

use strict qw(subs vars); no warnings;
use 5.010;

use Encode qw(encode);
use RDF::Trine;
use Scalar::Util qw();

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Mixin::RDF::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Mixin::RDF::VERSION   = '0.105';
}

sub _simple_rdf
{
	my $self  = shift;
	my $model = shift;

	my $id    = $self->id(1);

	return if $self->{'already_added'}->{"$model"};
	$self->{'already_added'}->{"$model"}++;

	foreach my $rdftype (@{ $self->format_signature->{'rdf:type'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$id,
			RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
			RDF::Trine::Node::Resource->new($rdftype),
			));
	}

	KEY: foreach my $key (sort keys %{ $self->format_signature->{'rdf:property'} })
	{
		my $rdf  = $self->format_signature->{'rdf:property'}->{$key};

		next KEY unless defined $self->data->{$key};

		my $vals = $self->data->{$key};
		$vals = [$vals] unless ref $vals eq 'ARRAY';

		foreach my $val (@$vals)
		{
			my $can_id      = Scalar::Util::blessed($val) && $val->can('id');
			my $seems_bnode = ($val =~ /^_:\S+$/);
			my $seems_uri   = ($val =~ /^[a-z0-9\.\+\-]{1,20}:\S+$/);

			if ((defined $rdf->{'resource'}||defined $rdf->{'rev'})
			&&  ($can_id || $seems_uri || $seems_bnode))
			{
				my $val_node = undef;
				if ($can_id)
				{
					$val_node = $val->id(1);
				}
				else
				{
					$val_node = ($val =~ /^_:(.*)$/) ? 
						RDF::Trine::Node::Blank->new($1) : 
						RDF::Trine::Node::Resource->new($val);
				}
				
				foreach my $prop (@{ $rdf->{'resource'} })
				{
					$model->add_statement(RDF::Trine::Statement->new(
						$id,
						RDF::Trine::Node::Resource->new($prop),
						$val_node
						));
				}
				
				foreach my $prop (@{ $rdf->{'rev'} })
				{
					$model->add_statement(RDF::Trine::Statement->new(
						$val_node,
						RDF::Trine::Node::Resource->new($prop),
						$id
						));
				}
				
				if ($can_id and Scalar::Util::blessed($val) and $val->can('add_to_model'))
				{
					$val->add_to_model($model);
				}
			}
			
			elsif (defined $rdf->{'literal'} and !$can_id)
			{
				foreach my $prop (@{ $rdf->{'literal'} })
				{
					$model->add_statement(RDF::Trine::Statement->new(
						$id,
						RDF::Trine::Node::Resource->new($prop),
						$self->_make_literal($val, $rdf->{'literal_datatype'}),
						));
				}
			}
		}
	}
}

sub _make_literal
{
	my ($self, $val, $dt) = @_;
	
	if (Scalar::Util::blessed($val)
	and $val->can('to_string')
	and $val->can('datatype'))
	{
		return RDF::Trine::Node::Literal->new(
			encode('utf8', $val->to_string), undef, $val->datatype);
	}
	elsif (Scalar::Util::blessed($val)
	and $val->can('to_string')
	and $val->can('lang'))
	{
		return RDF::Trine::Node::Literal->new(
			encode('utf8', $val->to_string), $val->lang);
	}
	else
	{
		if (defined $dt and length $dt and $dt !~ /:/)
		{
			$dt = 'http://www.w3.org/2001/XMLSchema#'.$dt;
		}
		if ($dt eq 'http://www.w3.org/2001/XMLSchema#integer')
		{
			$val = int $val;
		}
		
		return RDF::Trine::Node::Literal->new(encode('utf8', $val), undef, $dt);
	}
}

1;

__END__

=head1 NAME

HTML::Microformats::Mixin::RDF - RDF output mixin

=head1 DESCRIPTION

HTML::Microformats::Mixin::RDF provides some utility code for microformat
modules to more easily output RDF. It includes methods C<_simple_rdf> which
takes an RDF::Trine model as a parameter and adds some basic triples to it
based on the object's format signature; and C<_make_literal> taking either
a string plus datatype as parameters, or any of the HTML::Microformats::Datatype
objects, returning an RDF::Trine::Node::Literal.

HTML::Microformats::Format inherits from this module, so by extension, all the
microformat modules do too.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

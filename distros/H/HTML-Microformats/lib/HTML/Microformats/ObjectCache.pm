package HTML::Microformats::ObjectCache;

use strict qw(subs vars); no warnings;
use 5.010;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::ObjectCache::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::ObjectCache::VERSION   = '0.105';
}

sub new
{
	my $class = shift;
	my $self  = bless {}, $class;
	return $self;
}

sub set
{
	my $self  = shift;
	my $ctx   = shift;
	my $elem  = shift;
	my $klass = shift;
	my $obj   = shift;
	
	my $nodepath = $elem->getAttribute('data-cpan-html-microformats-nodepath');
	
	$self->{ $ctx->uri }->{ $klass }->{ $nodepath } = $obj;
	
	return $self->{ $ctx->uri }->{ $klass }->{ $nodepath };
}

sub get
{
	my $self  = shift;
	my $ctx   = shift;
	my $elem  = shift;
	my $klass = shift;
	
	my $nodepath = $elem->getAttribute('data-cpan-html-microformats-nodepath');

#	print sprintf("Cache %s on %s for %s.\n",
#		($self->{ $ctx->uri }->{ $klass }->{ $nodepath } ? 'HIT' : 'miss'),
#		$nodepath, $klass);

	return $self->{ $ctx->uri }->{ $klass }->{ $nodepath };
}

sub get_all
{
	my $self  = shift;
	my $ctx   = shift;
	my $klass = shift || undef;
	
	if (defined $klass)
	{
		return values %{ $self->{$ctx->uri}->{$klass} };
	}

	my @rv;
	foreach my $klass ( keys %{ $self->{$ctx->uri} } )
	{
		push @rv, (values %{ $self->{$ctx->uri}->{$klass} });
	}
	return @rv;
}

1;

__END__

=head1 NAME

HTML::Microformats::ObjectCache - cache for microformat objects

=head1 DESCRIPTION

Prevents microformats from being parsed twice within the same context.

This is not just for saving time. It also prevents the occasional infinite loop, and
makes sure identifiers are used consistently.

=head2 Constructor

=over

=item C<< $cache = HTML::Microformats::ObjectCache->new >>

Creates a new, empty cache.

=back

=head2 Public Methods

=over

=item C<< $cache->set($context, $package, $element, $object); >>

For a given context, package (e.g. 'HTML::Microformats::Format::hCard') and DOM
element node, stores an object in the cache.

=item C<< $object = $cache->get($context, $package, $element); >>

For a given context, package (e.g. 'HTML::Microformats::Format::hCard') and DOM
element node, retrieves an object from the cache.

=item C<< @objects = $cache->get_all($context, [$package]); >>

For a given context and package (e.g. 'HTML::Microformats::Format::hCard'), retrieves a
list of objects from within the cache.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>

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


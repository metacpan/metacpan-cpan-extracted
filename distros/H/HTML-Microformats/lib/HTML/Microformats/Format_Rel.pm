=head1 NAME

HTML::Microformats::Format_Rel - base rel-* microformat class

=head1 SYNOPSIS

 my @tags = HTML::Microformats::RelTag->extract_all(
                   $doc->documentElement, $context);
 foreach my $tag (@tags)
 {
   print $tag->get_href . "\n";
 }

=head1 DESCRIPTION

HTML::Microformats::Format_Rel inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=head2 Additional Methods

=over 4

=item C<< $relfoo->get_href() >>

Returns the absolute URL of the resource being linked to.

=item C<< $relfoo->get_label() >>

Returns the linked text of the E<lt>aE<gt> element. Microformats patterns
like value excerpting are used.

=item C<< $relfoo->get_title() >>

Returns the contents of the title attribute of the E<lt>aE<gt> element,
or the same as C<< $relfoo->get_label() >> if the attribute is not set.

=back

=cut

package HTML::Microformats::Format_Rel;

use base qw(HTML::Microformats::Format);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(stringify);

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format_Rel::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format_Rel::VERSION   = '0.105';
}

sub new
{
	my ($class, $element, $context) = @_;
	my $cache = $context->cache;
	
	return $cache->get($context, $element, $class)
		if defined $cache && $cache->get($context, $element, $class);
	
	my $self = {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		'id'         => $context->make_bnode($element) ,
		};
	
	bless $self, $class;
	
	$self->{'DATA'}->{'href'} = $context->uri( $element->getAttribute('href') );
	$self->{'DATA'}->{'label'}   = stringify($element, 'value');
	$self->{'DATA'}->{'title'}   = $element->hasAttribute('title')
	                             ? $element->getAttribute('title')
	                             : $self->{'DATA'}->{'label'};
	
	$cache->set($context, $element, $class, $self)
		if defined $cache;
	
	return $self;
}

1;

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Format>,
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


package HTML::TreeBuilder::Select;

use warnings;
use strict;

=head1 NAME

HTML::TreeBuilder::Select - Traverse a HTML tree using CSS selectors

=head1 VERSION

Version 0.111

=cut

our $VERSION = '0.111';

use HTML::TreeBuilder::XPath;
use Class::Accessor;
use base qw(HTML::TreeBuilder::XPath);

sub __container { my $self = shift; return $self->{__container} unless @_; return $self->{__container} = shift }
sub __fake_container { my $self = shift; return $self->{__fake_container} unless @_; return $self->{__fake_container} = shift }

=head1 SYNOPSIS

  my $tree = new HTML::TreeBuilder::Select

  my @entries = $tree->select("div.main div.entry");

=over 4

=item @elements = $tree->select(QUERY)

Search the tree for elements matching the C<QUERY>, which should be a CSS selector.

=item $tree->dump_HTML()

Returns a string representation of the tree in (possibly invalid) HTML format. This method will preserve any text outside of the root-level elements and NOT automatically wrap the content in <html><head></head><body> ... </body></html>. 

=cut

sub dump_HTML {
	my $self = shift;
	return unless my $container = $self->container;
	my @content;
	@content = $self->__fake_container ? $container->content_list : ($container);
	return join '', map { if (ref $_) { $_ = $_->as_HTML } $_ } @content;
}

=item my $element = $tree->container()

A convenience method that will return either the containing element of the tree, or a simple div container containing the root-level elements.  This is very similar to the C<guts> method, but C<container> will also remember whether the tree had a containing root element or not.

=cut

sub container {
	my $self = shift;
	my $container = $self->__container;
	return $container if $container;
	my @content = $self->guts;
	if (1 == @content && ref $content[0]) {
		$container = $content[0];
	}
	else {
		$self->__fake_container(1);
		$container = scalar $self->guts;
	}
	return unless $container;
	$self->__container($container);
	return $container;
}

=item $tree->delete()

Same as L<HTML::TreeBuilder::delete>

=cut

sub delete {
	my $self = shift;
	$self->__fake_container(undef);
	$self->__container(undef);
	return $self->SUPER::delete;
}

=back 

=cut

package HTML::Element;

use HTML::TreeBuilder::XPath;
use HTML::Selector::XPath qw(selector_to_xpath);
use Carp;

use constant _KEEP => "keep";
use constant _REPLACE => "replace";
use constant _DELETE => "delete";

sub select {
	my $self = shift;
	my $query = shift or croak "Need a query (a CSS selector or XPath)";
	my $operation = shift;

	my $path;
	if ($query =~ s/^~//) {
		$path = $query;
	}
	elsif (! ref $query) {
		$path = selector_to_xpath($query);
	}

	my @elements = $self->findnodes($path);

	return wantarray ? @elements : $elements[0] unless $operation;

	if (ref $operation eq "CODE") {
		for my $element (@elements) {
			my @result = $operation->($element);
			my $directive = shift @result;
			$directive &&= lc $directive;
			if (! $directive || $directive eq _KEEP) {
			}
			elsif ($directive eq _REPLACE) {
				my $replacement = shift @result;
				if (ref $replacement eq "ARRAY") {
					$replacement = HTML::Element->new_from_lol($replacement);
				}
				$element->replace_with($replacement)->delete;
			}
			elsif ($directive eq _DELETE) {
				$element->delete;
			}
		}
	}
	elsif ($operation =~ m/^#$/i) {
		return scalar @elements;
	}
	else {
		croak "Operation ($operation) not permitted";
	}
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-treebuilder-select at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-TreeBuilder-Select>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::TreeBuilder::Select

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-TreeBuilder-Select>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-TreeBuilder-Select>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-TreeBuilder-Select>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-TreeBuilder-Select>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::TreeBuilder::Select


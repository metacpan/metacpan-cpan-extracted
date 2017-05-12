
package 
    TestContainer;

use strict;
use warnings;

use base 'HTML::Widget::Container';

sub _build_element {
	my $self = shift;
	my $e = shift;

	return () unless $e;
	return map { $self->_build_element($_) } @{$e} if ref $e eq 'ARRAY';

	my $class = $e->attr('class') || '';

	$e = new HTML::Element('span', class => 'custom_fields_with_errors')->push_content($e->clone ) if $self->error && $e->tag eq 'input';

	my @list;

	push @list, $self->label, new HTML::Element('br') if $self->label;
	push @list, $e                                    if $e;
	
	return @list;
}

1;

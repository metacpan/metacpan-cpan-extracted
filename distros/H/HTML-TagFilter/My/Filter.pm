package My::Filter;

use base qw(HTML::TagFilter);
use strict;

sub on_open_tag {
	my ($self, $tag, $attributes, $sequence) = @_;
	$$tag = 'strong' if $$tag eq 'b';
}

sub on_close_tag {
	my ($self, $tag) = @_;
	$$tag = 'strong' if $$tag eq 'b';
}

1;

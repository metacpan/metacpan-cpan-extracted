use strict;
use warnings FATAL => 'all';

package HTML::Tested::List::Renderer;

sub init {}

sub render {
	my ($self, $the_list, $caller, $stash, $id) = @_;
	my $n = $the_list->name;
	my $rows = $caller->$n;
	my @res;
	my $i = 1;
	for my $row (@$rows) {
		my $s = {};
		$row->_ht_render_i($s, $id . "__" . $i++);
		push @res, $s;
	}
	$stash->{$n} = \@res;
}

1;

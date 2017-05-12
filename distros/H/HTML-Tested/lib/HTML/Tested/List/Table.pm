use strict;
use warnings FATAL => 'all';

package HTML::Tested::List::Table;
use Carp;
use Data::Dumper;

sub new { bless {}, shift(); }

sub init {
	my ($self, $the_list, $parent) = @_;
	my $c = $the_list->containee;
	my (@cols, @names);
	for my $w (@{ $c->Widgets_List }) {
		my $n = $w->name;
		my $ct = $c->ht_get_widget_option($n, "column_title");
		next unless defined($ct);
		push @cols, $ct;
		push @names, $n;
	}
	confess "No columns found!" unless @cols;
	$self->{_cols} = \@cols;
	$self->{_names} = \@names;
}

sub render {
	my ($self, $the_list, $caller, $stash, $id) = @_;
	my ($cols, $names) = ($self->{_cols}, $self->{_names});
	my $ln = $the_list->name;
	my $res = "<table>\n<tr>\n";
	for my $t (@$cols) {
		$res .= "<th>$t</th>\n";
	}
	for my $r (@{ $stash->{ $ln } }) {
		$res .= "</tr>\n<tr>\n";
		for my $n (@$names) {
			my $td = $r->{$n};
			confess "# No $n found in " . Dumper($r)
					unless defined($td);
			$res .= "<td>$td</td>\n";
		}
	}

	$res .= "</tr>\n</table>\n";
	$stash->{"$ln\_table"} = $res;
}

1;

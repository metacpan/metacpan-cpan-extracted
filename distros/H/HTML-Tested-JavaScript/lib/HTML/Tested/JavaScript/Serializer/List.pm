use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Serializer::List::Renderer;

sub render {
	my ($self, $the_list, $caller, $stash, $id) = @_;
	my $n = $the_list->name;
	my $rows = $caller->$n;
	my @strs;
	my $wl = $the_list->containee->Widgets_List;
	my $vc = 'HTML::Tested::JavaScript::Serializer::Value';
	my $ac = 'HTML::Tested::JavaScript::Serializer::Array';
	my @names = map { $_->name } grep { $_->isa($vc) || $_->isa($ac) } @$wl;

	for my $r (@{ $stash->{ $n } }) {
		push @strs, join(",\n\t", grep { defined($_) }
			map { $r->{$_} } @names);
	}
	my $ls = join("\n}, {\n\t", @strs);
	$stash->{"$n\_js"} = $ls ? "\"$n\": [ {\n\t$ls\n} ]" : "\"$n\": []";
}

package HTML::Tested::JavaScript::Serializer::List;
use base 'HTML::Tested::List';

sub new {
	my $self = shift()->SUPER::new(@_);
	push @{ $self->{renderers} }, __PACKAGE__ . "::Renderer";
	return $self;
}

1;

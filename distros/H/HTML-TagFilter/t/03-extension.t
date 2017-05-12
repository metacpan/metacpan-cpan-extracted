use strict;
use Test::More;
use HTML::TagFilter;

BEGIN {
    plan (tests => 4);
}

my $tf = HTML::TagFilter->new(
	log_rejects => 0,
	strip_comments => 1,
	on_start_document => sub {
		my ($self, $rawtext) = @_;
		$self->{_tag_stack} = [];
		$$rawtext .= " <a href=\"javascript:alert('boo');\">on_start_document</a>";
	},
);

my $tf2 = HTML::TagFilter->new(
	log_rejects => 0,
	strip_comments => 1,
	verbose => 1,
	on_start_document => sub {
		my ($self, $rawtext) = @_;
		$self->{_tag_stack} = [];
		return;
	},
	on_open_tag => sub {
		my ($self, $tag, $attributes, $sequence) = @_;
		push @{ $self->{_tag_stack} }, $$tag unless grep {$_ eq $$tag} qw(img br hr meta link);
		return;
	},
	on_close_tag => sub {
		my ($self, $tag) = @_;
		unless (@{ $self->{_tag_stack} } && grep {$_ eq $$tag} @{ $self->{_tag_stack} }) {
			undef ${ $tag };
			return;
		}
		my @unclosed;
		while (my $lasttag = pop @{ $self->{_tag_stack} })  {
			return join '', map "</$_>", @unclosed if $lasttag eq $$tag;
			push @unclosed, $lasttag;
		}
	},
	on_finish_document => sub {
		my ($self, $cleantext) = @_;
		return join '', map "</$_>", reverse @{ $self->{_tag_stack} };
	},
);

is( $tf->filter(qq|wake up|), qq|wake up <a>on_start_document</a>|, "basic callbacks working. text modified.");

is( $tf2->filter(
	qq|<p>Mother, I can feel the <b><i>soil</b> falling over <a href="javascript: bang();">my head</a>|), 
	qq|<p>Mother, I can feel the <b><i>soil</i></b> falling over <a>my head</a></p>|, "callbacks: unclosed tags closed");

is( $tf2->filter(
	qq|<p>Mother, I can feel the soil falling over my head</a>|), 
	qq|<p>Mother, I can feel the soil falling over my head</p>|, "callbacks: unopened tags omitted");

is( $tf2->filter(
	qq|<p>Mother, <strong>I can feel the <b><i>soil</b> falling over my <em>head</i>|), 
	qq|<p>Mother, <strong>I can feel the <b><i>soil</i></b> falling over my <em>head</em></strong></p>|, "callbacks: bad nesting mended");

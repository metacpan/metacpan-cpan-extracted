package HTML::ListScraper::Book;

use warnings;
use strict;

use Class::Generate qw(class);

class 'HTML::ListScraper::Tag' => {
    name => { type => '$', required => 1, readonly => 1 },
    index => { type => '$', required => 1, readonly => 1 },
    link => { type => '$', readonly => 1 },
    text => '$',
    '&append_text' => q{ $text .= $_[0]; }
};

sub new {
    my $class = shift;
    my $self = { shapeless => 0, index => 0,
		 dseq => [ ], next => 0, tseq => [ ], p2t => { } };

    # the list is from HTML 4.01 Transitional DTD; head and body is
    # included not because we seriously expect them to be unpaired,
    # but just to simplify documentation - they aren't going to get
    # into repeated sequences anyway...
    foreach (qw(area base basefont body br col colgroup dd dt frame head hr img input isindex li link meta option p param tbody td tfoot th thead tr)) {
        $self->{unclosed_tags}->{$_} = 1;
    }

    bless $self, $class;

    return $self;
}

sub shapeless {
    my $self = shift;

    if (@_) {
        $self->{shapeless} = !!$_[0];
    }

    return $self->{shapeless};
}

sub is_unclosed_tag {
    my ($self, $name) = @_;

    return exists($self->{unclosed_tags}->{$name});
}

sub push_item {
    my ($self, $name) = @_;

    my $index = ($self->{index})++;
    $self->_push(HTML::ListScraper::Tag->new(name => $name, index => $index));
}

sub push_link {
    my ($self, $name, $link) = @_;

    my $index = ($self->{index})++;
    $self->_push(HTML::ListScraper::Tag->new(
        name => $name, index => $index, link => $link));
}

sub get_internal_name {
    my ($self, $name) = @_;

    return exists($self->{p2t}->{$name}) ? $self->{p2t}->{$name} : undef;
}

sub intern_name {
    my ($self, $name) = @_;

    if (!exists($self->{p2t}->{$name})) {
        use bytes;

	my $c = ($self->{next})++;
	if ($self->{next} > 255) {
	    # 18Apr2007: HTML::ListScraper::get_known_sequence
	    # depends on 1-byte internal names
	    die "can't handle so many tags";
	    # could probably switch to 2-byte numbers, but is that
	    # useful?
	}

	$self->{p2t}->{$name} = bytes::chr($c);
    }

    return $self->{p2t}->{$name};
}

sub _push {
    my ($self, $td) = @_;

    my $name = $td->name;
    my $iname = $self->intern_name($name);
    push @{$self->{dseq}}, $td;
    push @{$self->{tseq}}, $iname;
}

sub append_text {
    my ($self, $text) = @_;

    my $count = scalar(@{$self->{dseq}});

    # ignore text before the first tag
    if (!$count) {
	return; # if we had a verbose mode, we would warn here
    }

    my $td = $self->{dseq}->[$count - 1];
    $td->append_text($text);
}

sub get_internal_sequence {
    my $self = shift;

    return wantarray ? @{$self->{tseq}} : $self->{tseq};
}

sub is_presentable {
    my ($self, $start, $len) = @_;

    if ($self->{shapeless}) {
        return 1;
    }

    my $i = 0;
    my @stack;
    while ($i < $len) {
        my $name = $self->{dseq}->[$start + $i]->name;
	my $tag = $name;
	$tag =~ s~^\/~~;

	if ($name eq $tag) {
	    push @stack, $tag;
	} else {
	    while (scalar(@stack) &&
		    ($stack[scalar(@stack) - 1] ne $tag)) {
		if ($self->is_unclosed_tag($stack[scalar(@stack) - 1])) {
		    pop @stack;
		} else {
		    return 0;
		}
	    }

	    if (!scalar(@stack)) {
	        return 0;
	    }

	    pop @stack;
	}

        ++$i;
    }

    while (scalar(@stack)) {
        my $top = pop @stack;
	if (!$self->is_unclosed_tag($top)) {
	    return 0;
	}
    }

    return 1;
}

sub get_all_tags {
    my $self = shift;

    return wantarray ? @{$self->{dseq}} : $self->{dseq};
}

sub get_tags {
    my ($self, $start, $len) = @_;

    my $last = $start + $len - 1;
    return @{$self->{dseq}}[$start .. $last];
}

sub get_tag {
    my ($self, $pos) = @_;

    return $self->{dseq}->[$pos];
}

1;

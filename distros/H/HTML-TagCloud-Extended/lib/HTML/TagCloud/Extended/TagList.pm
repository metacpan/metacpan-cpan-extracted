package HTML::TagCloud::Extended::TagList;
use strict;

sub new {
    my $class = shift;
    my $self  = bless {
        _tags => [],
    }, $class;
    return $self;
}

sub add {
    my($self, $tag) = @_;
    push @{ $self->{_tags} }, $tag;
}

sub count {
    my $self = shift;
    return scalar @{ $self->{_tags} };
}

sub get_tag_at {
    my ($self, $index) = @_;
    return $self->count > $index ? $self->{_tags}[$index] : undef;
}

sub splice {
    my ($self, $index, $num) = @_;
    $index ||= 0;
    my @tags = splice( @{ $self->{_tags} }, $index, $num );
    my $taglist = HTML::TagCloud::Extended::TagList->new;
    $taglist->add($_) for @tags;
    return $taglist;
}

sub sort {
    my ($self, $type) = @_;
    if ( $type eq 'name' ) {
        $self->{_tags} = [ sort { $a->name cmp $b->name } @{ $self->{_tags} } ];
    } elsif ( $type eq 'name_desc' ) {
        $self->{_tags} = [ sort { $b->name cmp $a->name } @{ $self->{_tags} } ];
    } elsif ( $type eq 'count') {
        $self->{_tags} = [ sort { $a->count <=> $b->count } @{ $self->{_tags} } ];
    } elsif ( $type eq 'count_desc' ) {
        $self->{_tags} = [ sort { $b->count <=> $a->count } @{ $self->{_tags} } ];
    } elsif ( $type eq 'timestamp' ) {
        $self->{_tags} = [ sort { $a->epoch <=> $b->epoch } @{ $self->{_tags} } ];
    } elsif ( $type eq 'timestamp_desc' ) {
        $self->{_tags} = [ sort { $b->epoch <=> $a->epoch } @{ $self->{_tags} } ];
    }
}

sub iterator {
    my $self = shift;
    return HTML::TagCloud::Extended::TagList::Iterator->new($self);
}

sub min_count {
    my $self = shift;
    my @tags = sort { $a->count <=> $b->count } @{ $self->{_tags} };
    return @tags > 0 ? $tags[0]->count : undef;
}

sub max_count {
    my $self = shift;
    my @tags = sort { $b->count <=> $a->count } @{ $self->{_tags} };
    return @tags > 0 ? $tags[0]->count : undef;
}

sub min_epoch {
    my $self = shift;
    my @tags = sort { $a->epoch <=> $b->epoch } @{ $self->{_tags} };
    return @tags > 0 ? $tags[0]->epoch : undef;
}

sub max_epoch {
    my $self = shift;
    my @tags = sort { $b->epoch <=> $a->epoch } @{ $self->{_tags} };
    return @tags > 0 ? $tags[0]->epoch : undef;
}

package HTML::TagCloud::Extended::TagList::Iterator;

sub new {
    my ($class, $tags) = @_;
    my $self = bless {
        tags   => $tags,
        _index => 0,
    }, $class;
    return $self;
}

sub reset {
    my $self = shift;
    $self->{_index} = 0;
}

sub next {
    my $self = shift;
    return undef unless ( $self->{tags}->count > $self->{_index} );
    my $tag = $self->{tags}->get_tag_at($self->{_index});
    $self->{_index}++;
    return $tag;
}

sub first {
    my $self = shift;
    return $self->{tags}->get_tag_at(0);
}

1;
__END__


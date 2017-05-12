# $Id: /local/perl/HTML-TagClouder/trunk/lib/HTML/TagClouder/Collection/Simple.pm 11407 2007-05-23T11:58:17.952570Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package HTML::TagClouder::Collection::Simple;
use strict;
use warnings;
use base qw(HTML::TagClouder::Collection);

__PACKAGE__->mk_accessors($_) for qw(tags);

sub new
{
    my $class = shift;
    my $self  = $class->next::method(@_, iterator_class => 'HTML::TagClouder::Collection::Simple::Iterator');
    $self->tags([]);
    return $self;
}

sub add
{
    my $self = shift;
    my $tag  = shift;
    push @{ $self->tags }, $tag unless $tag->count == 0;
}

sub sort
{
    my $self = shift;
    my $strategy = shift;

    $strategy ||= '';

    if ($strategy eq 'count') {
        $self->tags([ sort { ($a->count || 0) <=> ($b->count || 0) } @{ $self->tags } ]);
    } else {
        $self->tags([return sort { ($a->label || '') cmp ($b->label || '') } @{ $self->tags } ]);
    }
}

package HTML::TagClouder::Collection::Simple::Iterator;
use strict;
use warnings;
use base qw(HTML::TagClouder::Iterator);

sub new 
{
    my $class = shift;
    my $collection = shift;

    my $self = bless {
        collection => $collection,
        current => 0,
    }, $class;

    return $self;
}

sub next
{
    my $self = shift;
    return $self->{collection}->tags->[ $self->{current}++ ];
}

sub reset
{
    my $self = shift;
    $self->{current} = 0;
}


1;

__END__

=head1 NAME

HTML::TagClouder::Collection::Simple - A Simple Tag Collection

=head1 METHODS

=head2 new

=head2 add

=head2 sort

Sorts the tags

=cut

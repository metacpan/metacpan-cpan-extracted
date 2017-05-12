# $Id: /local/perl/HTML-TagClouder/trunk/lib/HTML/TagClouder/Processor/Simple.pm 11418 2007-05-24T00:52:24.708742Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package HTML::TagClouder::Processor::Simple;
use strict;
use warnings;
use base qw(HTML::TagClouder::Processor);

__PACKAGE__->mk_accessors($_) for qw(font_max font_base font_trunc_step);

sub new
{
    my $class = shift;
    $class->next::method(font_max => 250, font_base => 100, font_trunc_step => 5, @_);
}

sub process
{
    my $self = shift;
    my $cloud = shift;

    my $collection = $cloud->collection;
    $collection->sort;

    my $iterator   = $collection->iterator();
    my $font_base  = $self->font_base;
    my $font_max   = $self->font_max;
    my $trunc_step = int($self->font_trunc_step);

    my $min_count = undef;
    my $max_count = 0;
    while (my $tag = $iterator->next ) {
        $min_count = $tag->count if ! defined $min_count || $min_count > $tag->count;
        $max_count = $tag->count if $max_count < $tag->count;
    }
    $iterator->reset;

    my $diff = $max_count - $min_count;
    my $k = $diff == 0 ? 1 : ($font_max - $font_base) / ($diff ** 2);

    while (my $tag = $iterator->next) {
        my $norm = int($k * (($tag->count - $min_count) ** 2));

        if ($trunc_step > 0) {
            my $remainder = $norm % 5;
            if ($remainder > 0) {
                $norm += 5 - $remainder;
            }
        }

        $tag->count_norm( $norm + $font_base );
    }
}

1;

__END__

=head1 NAME

HTML::TagClouder::Processor::Simple - A Simple Tag Processor

=head1 METHODS

=head2 new

=head2 process

=cut

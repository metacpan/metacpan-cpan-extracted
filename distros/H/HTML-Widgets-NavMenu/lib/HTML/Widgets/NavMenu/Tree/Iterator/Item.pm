package HTML::Widgets::NavMenu::Tree::Iterator::Item;

use strict;
use warnings;

use base qw(HTML::Widgets::NavMenu::Object);

__PACKAGE__->mk_acc_ref([qw(
    _node
    _subs
    _sub_idx
    _visited
    _accum_state
)]);

=head1 NAME

HTML::Widgets::NavMenu::Tree::Iterator::Item - an item for the tree iterator.

=head1 SYNOPSIS

For internal use only.

=cut

sub _init
{
    my ($self, $args) = @_;

    $self->_node($args->{'node'}) or
        die "node not specified!";

    $self->_subs($args->{'subs'}) or
        die "subs not specified!";

    $self->_sub_idx(-1);
    $self->_visited(0);

    $self->_accum_state($args->{'accum_state'}) or
        die "accum_state not specified!";

    return 0;
}

sub _is_visited
{
    my $self = shift;
    return $self->_visited();
}

sub _visit
{
    my $self = shift;

    $self->_visited(1);

    if ($self->_num_subs_to_go())
    {
        return $self->_subs()->[$self->_sub_idx($self->_sub_idx()+1)];
    }
    else
    {
        return undef;
    }
}

sub _visited_index
{
    my $self = shift;

    return $self->_sub_idx();
}

sub _num_subs_to_go
{
    my $self = shift;
    return $self->_num_subs() - $self->_sub_idx() - 1;
}

sub _num_subs
{
    my $self = shift;
    return scalar(@{$self->_subs()});
}

sub _get_sub
{
    my $self = shift;
    my $sub_num = shift;

    return $self->_subs()->[$sub_num];
}

sub _li_id {
    return shift->_node->li_id();
}

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;


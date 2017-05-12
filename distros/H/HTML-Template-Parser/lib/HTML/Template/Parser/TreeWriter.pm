package HTML::Template::Parser::TreeWriter;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw( context ));

sub write {
    my($self, $node) = @_;

    my $type = $self->get_type($node);

    my $pre  = "_pre_$type";
    my $main = "_main_$type";
    my $map  = "_map_$type";
    my $join = "_join_$type";
    my $post = "_post_$type";

    my $out = '';

    if($self->can($pre)){
        $out .= $self->$pre($node);
    }

    if($self->can($main)){
        $out .= $self->$main($node);
    }else{
        my @children_out;
        if ($self->can($map)) {
            @children_out = $self->$map($node);
        } else {
            @children_out = map { $self->write($_); } $self->get_node_children($node);
        }

        if ($self->can($join)) {
            $out .= $self->$join($node, \@children_out);
        } else {
            $out .= join('', @children_out);
        }
    }

    if($self->can($post)){
        $out .= $self->$post($node);
    }

    $out;
}

sub create_and_push_context {
    my $self = shift;
    my $new_context = {};
    push(@{$self->context}, $new_context);
    $new_context;
}

sub pop_context {
    my $self = shift;
    if(@{$self->context} < 1){
        die "Internal error. context is empty.\n";
    }
    pop(@{$self->context});
}

sub get_context_depth {
    my $self = shift;
    scalar(@{$self->context});
}

sub current_context {
    my $self = shift;

    if(@{$self->context}){
        return $self->context->[-1];
    }
    return;
}

1;

package Forward::Routes::Resources;
use strict;
use warnings;
use parent qw/Forward::Routes/;

use Forward::Routes::Resources::Plural;
use Forward::Routes::Resources::Singular;
use Carp;


sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self->initialize(@_);
}


sub add_member_route {
    my $self = shift;
    my ($pattern, @params) = @_;

    my $members = $self->members;

    # makes sure that inheritance works
    my $child = Forward::Routes->new($pattern, @params);
    $members->add_child($child);

    # name
    my $member_route_name = $pattern;
    $member_route_name =~s|^/||;
    $member_route_name =~s|/|_|g;


    # Auto set controller and action params and name
    $child->to($self->{_ctrl} . '#' . $member_route_name);
    $child->name($self->{name} . '_' . $member_route_name);

    return $child;
}


sub id_constraint {
}


sub init_options {
    my $self = shift;
    my ($options) = @_;

    # default
    $self->id_constraint(qr/[^.\/]+/);

    # only resource specific options
    if ($options) {
        $self->id_name($options->{id_name}) if $options->{id_name};
        my $id_name = $options->{id_name} || 'id';

        $self->id_constraint($options->{constraints}->{$id_name}) if $options->{constraints}->{$id_name};
        $self->{only} = $options->{only};
        $self->{as} = $options->{as};
    }
}


sub preprocess {
    my $self = shift;

    my $current_namespace = $self->namespace || '';
    my $parent_namespace = '';
    my $parent_is_plural_resource;
    if ($self->parent) {
        $parent_namespace  = $self->parent->namespace || '';
        $parent_is_plural_resource = 1 if $self->parent->_is_plural_resource;
    }

    my $ns_name_prefix =
      $current_namespace ne $parent_namespace || !$parent_is_plural_resource && $current_namespace
        ? Forward::Routes::Resources->namespace_to_name($current_namespace) . '_'
        : '';
    my $route_name = ($self->{nested_resources_parent_name} ? $self->{nested_resources_parent_name} . '_' : '') . $ns_name_prefix . $self->{resource_name};
    $self->name($route_name);

    my $ctrl = Forward::Routes::Resources->format_resource_controller->($self->{resource_name});
    $self->_ctrl($ctrl);
}


sub members {
    my $self = shift;
    return $self;
}


sub namespace_to_name {
    my $self = shift;
    my ($namespace) = @_;

    my @new_parts;

    my @parts = split /::/, $namespace;

    for my $part (@parts) {
        my @words;
        while ($part =~ s/([A-Z]{1}[^A-Z]*)//){
            my $word = lc $1;
            push @words, $word;
        }
        push @new_parts, join '_', @words;
    }
    return join '_', @new_parts;
}


sub _adjust_nested_resources {
    my $self = shift;
    my ($parent) = @_;

    $parent->_is_plural_resource || return;

    # no adjustment of id name if custom id name set
    my $parent_id_name = $parent->id_name ? $parent->id_name : $self->singularize->($parent->resource_name) . '_id';

    my $old_pattern = $self->pattern->pattern;

    $self->pattern->pattern(':' . $parent_id_name . '/' . $old_pattern);
    $self->constraints($parent_id_name => $parent->{id_constraint});


    if (defined $parent->name) {
        $self->{nested_resources_parent_name} = $parent->name;
    }
}


sub _ctrl {
    my $self = shift;
    my (@params) = @_;

    return $self->{_ctrl} unless @params;

    $self->{_ctrl} = $params[0];

    return $self;
}


sub _prepare_resource_options {
    my $self = shift;
    my (@names) = @_;

    my @final;
    while (@names) {
        my $name = shift(@names);

        if ($name =~m/^-/){
            $name =~s/^-//;
            push @final, {} unless ref $final[-1] eq 'HASH';
            $final[-1]->{$name} = shift(@names);
        }
        else {
            push @final, $name;
        }
    }
    return \@final;
}


1;

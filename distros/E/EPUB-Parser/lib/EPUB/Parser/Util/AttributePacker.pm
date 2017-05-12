package EPUB::Parser::Util::AttributePacker;
use strict;
use warnings;
use Carp;

sub ordered_list {
    my $class = shift;
    my $nodes = shift || [];
    my $item_list;

    for my $node ( @$nodes ) {
        my $attr_container;
        for my $attr ($node->attributes) {
            $attr_container->{$attr->name} = $attr->value;
        }
        push @$item_list, $attr_container;
    }

    return $item_list;
}


sub grouped_list {
    my $class = shift;
    my $nodes = shift || [];
    my $want_group = (shift || {})->{group};

    my $group_list;

    for my $node ( @$nodes ) {
        my $attr_container;
        for my $attr ($node->attributes) {
            $attr_container->{$attr->name} = $attr->value;
        }
        my $attr_group = delete $attr_container->{$want_group};

        push @{$group_list->{$attr_group}}, $attr_container;
    }

    return $group_list;

}

sub by_uniq_key {
    my $class = shift;
    my $nodes = shift || [];
    my $key = (shift || {})->{key};

    my $by_uniq_key;

    for my $node ( @$nodes ) {
        my $attr_container;
        for my $attr ($node->attributes) {
            $attr_container->{$attr->name} = $attr->value;
        }

        my $attr_key = delete $attr_container->{$key};
        $by_uniq_key->{$attr_key} =  $attr_container;
    }

    return $by_uniq_key;

}


1;


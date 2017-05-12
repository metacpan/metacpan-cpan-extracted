# -*-perl-*-
# Creation date: 2003-01-05 20:47:52
# Authors: Don
# Change log:
# $Id: Item.pm,v 1.6 2005/06/16 15:03:00 don Exp $
#
# Copyright (c) Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

use strict;
use Carp;

{   package HTML::Menu::Hierarchical::Item;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    sub new {
        my ($proto, $name, $info, $children, $item_hash) = @_;
        my $self = bless {}, ref($proto) || $proto;
        $self->setName($name);
        $self->setInfo($info);
        $self->setChildren($children);
        
        my $other_fields = {};
        while (my ($field, $value) = each %$item_hash) {
            if ($field eq 'name' or $field eq 'info' or $field eq 'children') {
                next;
            }
            $$other_fields{$field} = $value;
        }
        $self->setOtherFields($other_fields);
        
        return $self;
    }

    sub hasChildren {
        my ($self) = @_;
        my $children = $self->getChildren;
        if ($children and @$children) {
            return 1;
        }
        return undef;
    }
    
    #####################
    # getters and setters
    
    sub getName {
        my ($self) = @_;
        return $$self{_name};
    }
    
    sub setName {
        my ($self, $name) = @_;
        $$self{_name} = $name;
    }

    sub getInfo {
        my ($self) = @_;
        return $$self{_info};
    }

    sub setInfo {
        my ($self, $info) = @_;
        $$self{_info} = $info;
    }

    sub getChildren {
        my ($self) = @_;
        return $$self{_children};
    }

    sub setChildren {
        my ($self, $children) = @_;
        $$self{_children} = $children;
    }

    sub addChild {
        my $self = shift;
        my $child = shift;

        return undef unless $child;
        
        my $children = $self->{_children};
        unless ($children and UNIVERSAL::isa($children, 'ARRAY')) {
            $children = [];
            $self->{_children} = $children;
        }

        if (UNIVERSAL::isa($child, 'HASH')) {
            push @$children, $child;
        } elsif (UNIVERSAL::isa($child, 'ARRAY')) {
            push @$children, @$child;
        }

        return 1;
    }

    sub getOtherFields {
        my ($self) = @_;
        return $$self{_other_fields};
    }

    sub setOtherFields {
        my ($self, $hash) = @_;
        $$self{_other_fields} = $hash;
    }

    sub getOtherField {
        my ($self, $field) = @_;
        my $fields = $self->getOtherFields;
        return $$fields{$field};
    }

}

1;

__END__

=head1 NAME


=head1 SYNOPSIS


=head1 EXAMPLES


=head1 Version

$Id: Item.pm,v 1.6 2005/06/16 15:03:00 don Exp $

=cut

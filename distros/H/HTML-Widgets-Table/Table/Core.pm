# -*-perl-*-
# Creation date: 2003-09-08 08:10:51
# Authors: Don
# Change log:
# $Id: Core.pm,v 1.2 2003/09/14 07:36:15 don Exp $
#
# Copyright (c) 2003 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

use strict;

{   package HTML::Widgets::Table::Core;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    sub new {
        my ($proto) = @_;
        my $self = bless {}, ref($proto) || $proto;
        return $self;
    }

    sub _getAttributeStringFromHash {
        my ($self, $hash) = @_;
        my @pairs;
        foreach my $key (sort keys %$hash) {
            my $val = $$hash{$key};
            push @pairs, qq{$key="$val"};
        }
        return join(" ", @pairs);
    }

    sub _getParams {
        return shift()->{_params} || {};
    }

    # add in defaults
    sub _getRenderAttr {
        my ($self) = @_;
        my $params = $self->_getParams;
        my $defaults = $self->can('_getDefaultParams') ? $self->_getDefaultParams : {};
        my $non_attr = $self->can('_getNonAttrParams') ? $self->_getNonAttrParams : {};
        my $render_params = {};
        foreach my $key (keys %$params) {
            $$render_params{$key} = $$params{$key} unless exists $$non_attr{$key};
        }
        foreach my $key (keys %$defaults) {
            $$render_params{$key} = $$defaults{$key} unless exists($$params{$key});
        }
        return $render_params;
    }

}

1;

__END__

=pod

=head1 NAME

 HTML::Widgets::Table::Core - 

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS


=head1 EXAMPLES


=head1 BUGS


=head1 AUTHOR


=head1 VERSION

$Id: Core.pm,v 1.2 2003/09/14 07:36:15 don Exp $

=cut

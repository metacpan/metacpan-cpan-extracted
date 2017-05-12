# -*-perl-*-
# Creation date: 2003-09-06 13:10:07
# Authors: Don
# Change log:
# $Id: Row.pm,v 1.6 2003/09/14 07:36:15 don Exp $
#
# Copyright (c) 2003 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

use strict;

use HTML::Widgets::Table::Core;
use HTML::Widgets::Table::Cell;

{   package HTML::Widgets::Table::Row;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    use base 'HTML::Widgets::Table::Core';

    sub new {
        my ($proto, $params) = @_;
        $params = {} unless ref($params) eq 'HASH';
        my $self = bless { _params => $params, _cells => [] }, ref($proto) || $proto;
        return $self;
    }

    sub isHeaderRow {
        return shift()->_getParams()->{header};
    }

    sub _getNonAttrParams {
        return { header => 1,
               };
    }

    sub addCell {
        my ($self, $data, $params) = @_;

        if (UNIVERSAL::isa($data, 'HTML::Widgets::Table::Cell')) {
            push @{$$self{_cells}}, $data;
            return 1;
        }
        
        $params = {} unless ref($params) eq 'HASH';
        my $row_params = $self->_getParams;
        my $new_params = $params;
        $new_params = { %$params, header => $$row_params{header} } if $$row_params{header};
        my $cell = $self->getNewCellObj($data, $new_params);
        push @{$$self{_cells}}, $cell;

        return 1;
    }
    
    sub getNewCellObj {
        my ($self, $data, $params) = @_;
        return HTML::Widgets::Table::Cell->new($data, $params);
    }

    sub render {
        my ($self, $render_params, $overridable_params) = @_;
        $render_params = {} unless ref($render_params) eq 'HASH';
        $overridable_params = {} unless ref($overridable_params) eq 'HASH';

        my $render_attr = $self->_getRenderAttr;
        foreach my $key (keys %$render_params) {
            $$render_attr{$key} = $$render_params{$key};
        }
        foreach my $key (keys %$overridable_params) {
            $$render_attr{$key} = $$overridable_params{$key} unless exists $$render_attr{$key};
        }
        my $attr_str = $self->_getAttributeStringFromHash($render_attr);
        $attr_str = ' ' . $attr_str unless $attr_str eq '';
        my $str;
        $str .= "<tr$attr_str>\n";
        $str .= join("\n", map { $_->render } @{$$self{_cells}} ) . "\n";
        $str .= "</tr>\n";
        return $str;
    }

}

1;

__END__

=pod

=head1 NAME

 HTML::Widgets::Table::Row - 

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS


=head1 EXAMPLES


=head1 BUGS


=head1 AUTHOR


=head1 VERSION

$Id: Row.pm,v 1.6 2003/09/14 07:36:15 don Exp $

=cut

# -*-perl-*-
# Creation date: 2003-09-06 13:30:01
# Authors: Don
# Change log:
# $Id: Cell.pm,v 1.4 2003/09/14 07:36:15 don Exp $
#
# Copyright (c) 2003 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

use strict;

use HTML::Widgets::Table::Core;

{   package HTML::Widgets::Table::Cell;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    use base 'HTML::Widgets::Table::Core';

    sub new {
        my ($proto, $data, $params) = @_;
        $params = {} unless ref($params) eq 'HASH';
        my $self = bless { _data => $data, _params => $params }, ref($proto) || $proto;
        return $self;
    }

    sub render {
        my ($self) = @_;
        my $params = $$self{_params};
        my $attr = $self->_getRenderAttr;
        if ($$params{pretty_border_background} ne '') {
            $$attr{bgcolor} = $$params{pretty_border_background} unless exists $$attr{bgcolor};
        }

        my $str;
        my $data = $$self{_data};
        if (ref($data) eq 'HASH') {
            my $hash = $data;
            $data = $$hash{data};
            if (ref($$hash{attr}) eq 'HASH') {
                $attr = { %$attr, %{$$hash{attr}} };
            }
        }
        my $attr_str = $self->_getAttributeStringFromHash($attr);
        $attr_str = ' ' . $attr_str unless $attr_str eq '';

        my $tag_name = $$params{header} ? 'th' : 'td';
        return qq{<$tag_name$attr_str>$data</$tag_name>};
    }

    sub _getNonAttrParams {
        return { pretty_border_background => 1, header => 1 };
    }

}

1;

__END__

=pod

=head1 NAME

 HTML::Widgets::Table::Cell - 

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS


=head1 EXAMPLES


=head1 BUGS


=head1 AUTHOR


=head1 VERSION

$Id: Cell.pm,v 1.4 2003/09/14 07:36:15 don Exp $

=cut

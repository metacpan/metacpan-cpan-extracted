# -*-perl-*-
# Creation date: 2003-01-05 21:34:34
# Authors: Don
# Change log:
# $Id: ItemInfo.pm,v 1.30 2005/06/16 15:03:00 don Exp $
#
# Copyright (c) 2003 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# The underscore separated versions of the methods added for
# version v0_03 by request.

=pod

=head1 NAME

 HTML::Menu::Hierarchical::ItemInfo - Used by HTML::Menu::Hierarchical.
 Provides information about the menu item being processed.

=head1 SYNOPSIS

 Created by HTML::Menu::Hierarchical objects.

=head1 DESCRIPTION

 Information holder/gatherer representing one menu item.

=head1 METHODS

=head2 Getting back information

=cut

use strict;
use Carp;

{   package HTML::Menu::Hierarchical::ItemInfo;

    use vars qw($VERSION $AUTOLOAD);
    $VERSION = do { my @r=(q$Revision: 1.30 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
    
    sub new {
        my ($proto, $item, $selected_path, $key, $parent, $params) = @_;
        my $self = bless {}, ref($proto) || $proto;
        $self->setItem($item);
        $self->_setSelectedPath($selected_path);
        $self->setKey($key);
        $self->setParent($parent);
        $self->_setParams($params);
        return $self;
    }

=pod

=head2 hasChildren()

 Returns true if the current item has child items in the
 configuration.  False otherwise.

=cut
    sub hasChildren {
        my ($self) = @_;
        return $self->getItem()->hasChildren;
    }
    *has_children = \&hasChildren;

=pod

=head2 isSelected()

 Returns true if the current item is the selected one.

=cut
    sub isSelected {
        my ($self) = @_;
        my $key = $self->getKey;
        if ($self->getItem()->getName eq $self->getKey) {
            return 1;
        }
        
        return undef;
    }
    *is_selected = \&isSelected;

=pod

=head2 isInSelectedPath()

 Returns true if the current item is in the path from the root of
 the hierarchy to the selected item.

=cut
    sub isInSelectedPath {
        my ($self) = @_;
        my $selected_path = $self->_getSelectedPath;
        my $my_item = $self->getItem;

        foreach my $item (@$selected_path) {
            return 1 if $item == $my_item;
        }
        return undef;
    }
    *is_in_selected_path = \&isInSelectedPath;

=pod

=head2 getSelectedItem()

 Returns the ItemInfo object corresponding to the selected menu
 item.

=cut
    sub getSelectedItem {
        my ($self) = @_;
        my $selected_path = $self->_getSelectedPath;
        my $last_index = $#$selected_path;
        return undef if $last_index < 0;
        return $self->new($$selected_path[$last_index], $selected_path, $self->getKey);
    }
    *get_selected_item = \&getSelectedItem;
    *getSelectedItemInfo = \&getSelectedItem;
    *get_selected_item_info = \&getSelectedItem;

=pod

=head2 getSelectedLevel()

 Returns the level in the hierarchy where the selected menu item
 is located.  Levels start at zero.

=cut
    sub getSelectedLevel {
        my ($self) = @_;
        my $selected_path = $self->_getSelectedPath;
        return $#$selected_path;
    }
    *get_selected_level = \&getSelectedLevel;

=pod

=head2 getMaxDisplayedLevel()

 Returns the maximum level in the hierarchy to currently be
 displayed.

=cut
    sub getMaxDisplayedLevel {
        my ($self) = @_;
        my $selected_path = $self->_getSelectedPath;
        my $max_level = $#$selected_path;
        return $max_level if $max_level < 0;
        if ($$selected_path[$max_level]->hasChildren) {
            $max_level++;
        }
        return $max_level;
    }
    *get_max_displayed_level = \&getMaxDisplayedLevel;

    sub getStandardCallbackParams {
        my ($self) = @_;
        my $params = $self->_getParam('std_callback_params');
        unless (ref($params) eq 'HASH') {
            $params = {};
        }
        return $params;
    }
    
    sub _checkOpenAllFields {
        my ($self) = @_;

        if (exists($$self{_is_open_all})) {
            return $$self{_is_open_all};
        }

        my ($is_set, $val) = $self->_checkOpenField('open_all', '_is_open_all');
        if ($is_set) {
            return ($is_set, $val);
        }
        my $parent = $self;
        while ($parent = $parent->getParent) {
            my ($is_set, $val) = $parent->_checkOpenField('open_all', '_is_open_all');
            if ($is_set) {
                $$self{_is_open_all} = $val;
                return ($is_set, $val);
            }
        }

        $$self{_is_open_all} = undef;

        return (undef, undef);
    }

    sub _checkOpenField {
        my ($self, $field, $attr) = @_;
        unless (defined($field)) {
            $field = 'open';
            $attr = '_is_open';
        }

        if (my $open = $self->getOtherField($field)) {
            # simple case first
            unless (ref($open)) {
                $$self{$attr} = 1;
                return (1, 1);
            }
        
            # now allow for a subroutine reference
            if (ref($open) eq 'CODE') {
                my $rv = &$open();
                $$self{$attr} = $rv;
                return (1, $rv);
            } elsif (ref($open) eq 'ARRAY') {
                my ($obj, $func, @args) = @$open;
                my $rv;
                if (defined($obj)) {
                    $rv = $obj->$func(@args);
                } else {
                    $rv = &$func(@args);
                }
                $$self{$attr} = $rv;
                return (1, $rv);
            }
        }                       # end 'open' field check

        return (undef, undef);
    }

=pod

=head2 isOpen()

 Returns true if the current menu item is open, i.e., the current
 item has child items and is also in the open path.  Return false
 otherwise.

=cut
    sub isOpen {
        my ($self) = @_;
        if (exists($$self{_is_open})) {
            return $$self{_is_open};
        }

        return 1 if $self->_hasSetOpenAll;

        my ($is_set, $val) = $self->_checkOpenField;
        return $val if $is_set;

        ($is_set, $val) = $self->_checkOpenAllFields;
        return $val if $is_set;
        
        my $this_item = $self->getItem;
        unless ($this_item->hasChildren) {
            $$self{_is_open} = undef;
            return undef;
        }
        
        my $selected_path = $self->_getSelectedPath;
        my $name = $this_item->getName;
        
        foreach my $item (@$selected_path) {
            if ($item->getName eq $name) {
                # print $item->getName . " eq $name\n";
                $$self{_is_open} = 1;
                return 1;
            }
        }

        $$self{_is_open} = undef;
        return undef;
    }
    *is_open = \&isOpen;

=pod

=head2 isFirstDisplayed()

 Returns true if the current menu item is the first one to be
 displayed.

=cut
    # added for v0_02
    sub isFirstDisplayed {
        my ($self) = @_;
        my $item = $self->getPreviousItem;
        if ($item) {
            return undef;
        } else {
            return 1;
        }
    }
    *is_first_displayed = \&isFirstDisplayed;

=pod

=head2 isLastDisplayed()

 Returns true if the current menu item is the last to be
 displayed.

=cut
    # added for v0_02
    sub isLastDisplayed {
        my ($self) = @_;
        my $item = $self->getNextItem;
        if ($item) {
            return undef;
        } else {
            return 1;
        }
    }
    *is_last_displayed = \&isLastDisplayed;

=pod


=head2 isFirstSiblingDisplayed()

 Returns true if the current menu item is the first of its
 siblings to be displayed, false otherwise.

=cut
    sub isFirstSiblingDisplayed {
        my ($info_obj) = @_;
        my $self = $info_obj;
        
        my $my_level = $self->getLevel;
        my $item = $self;
        while (1) {
            $item = $self->getPreviousItem;
            return 1 unless $item;
            my $level = $item->getLevel;
            return undef if $level > $my_level;
            return undef if $level == $my_level;
            return 1 if $level < $my_level;
        }
        
        return undef;
    }
    *is_first_sibling_displayed = \&isFirstSiblingDisplayed;

=head2 isLastSiblingDisplayed()

 Returns true if the current menu item is the last of its
 siblings to be displayed, false otherwise.

=cut
    sub isLastSiblingDisplayed {
        my ($self) = @_;
        my $my_level = $self->getLevel;
        my $item = $self;

        while (1) {
            $item = $item->getNextItem;
            return 1 unless $item;
            my $level = $item->getLevel;
            return 1 if $level < $my_level;
            return undef if $level == $my_level;
        }
        
        return undef;
    }

    *is_last_sibling_displayed = \&isLastSiblingDisplayed;

=pod

=head2 getInfo()

 Returns the value of the 'info' field for the current menu item
 in the navigation configuration.

 Instead of getting the 'info' hash and then accessing a field
 within it, you may call a method to get that field directly.
 This is implemented with AUTOLOAD, so if you do something like

    my $text = $info_obj->getText;
    my $image_src = $info_obj->getImageSrc;

        or

    my $text = $info_obj->getText;
    my $image_src = $info_obj->get_image_src;

 you will be given back the corresponding values in the 'info'
 hash.

=cut
    sub getInfo {
        my ($self) = @_;
        return $self->getItem()->getInfo;
    }
    *get_info = \&getInfo;

    sub _getOtherFields {
        my ($self) = @_;
        return $self->getItem()->getOtherFields;
    }

    # get field from configuration that is at the same level as
    # the name and children fields
    sub getOtherField {
        my ($self, $field) = @_;
        my $fields = $self->_getOtherFields;
        return $$fields{$field};
    }

=pod

=head2 getName()

 Returns the 'name' field for the current menu item in the
 navigation configuration.  This is used to determine which menu
 item has been selected.

=cut
    sub getName {
        my ($self) = @_;
        return $self->getItem()->getName;
    }
    *get_name = \&getName;

    #####################
    # getters and setters

=pod

=head2 getNextItem()

 Returns the ItemInfo object corresponding to the next displayed
 menu item.

=cut
    sub getNextItem {
        my ($self) = @_;
        return $$self{_next_item};
    }
    *get_next_item = \&getNextItem;

    sub setNextItem {
        my ($self, $item) = @_;
        $$self{_next_item} = $item;
    }

=pod

=head2 getPreviousItem()

 Returns the ItemInfo object corrsponding to the previously
 displayed menu item.

=cut
    sub getPreviousItem {
        my ($self) = @_;
        return $$self{_previous_item};
    }
    *get_previous_item = \&getPreviousItem;

    sub setPreviousItem {
        my ($self, $item) = @_;
        $$self{_previous_item} = $item;
    }

    sub getKey {
        my ($self) = @_;
        return $$self{_key};
    }
    
    sub setKey {
        my ($self, $key) = @_;
        $$self{_key} = $key;
    }

=pod

=head2 getLevel()

 Returns the level in the menu hierarchy where the current menu
 item is located.  Levels start at zero.

=cut
    sub getLevel {
        my ($self) = @_;
        return $$self{_level};
    }
    *get_level = \&getLevel;

    sub setLevel {
        my ($self, $level) = @_;
        $$self{_level} = $level;
    }

    sub _getSelectedPath {
        my ($self) = @_;
        return $$self{_selected_path};
    }

    sub _setSelectedPath {
        my ($self, $path) = @_;
        $$self{_selected_path} = $path;
    }
    
    sub getItem {
        my ($self) = @_;
        return $$self{_item};
    }
    
    sub setItem {
        my ($self, $item) = @_;
        $$self{_item} = $item;
    }

=pod

=head2 getParent()

 Returns the info object for the current item's parent.

=cut

    sub getParent {
        my ($self) = @_;
        return $$self{_parent};
    }

    sub setParent {
        my ($self, $parent) = @_;
        $$self{_parent} = $parent;
    }

    # added for v0_07
    sub _getParams {
        my ($self) = @_;
        return $$self{_params} || {};
    }

    # added for v0_07
    sub _setParams {
        my ($self, $params) = @_;
        $$self{_params} = $params;
    }

    # added for v0_08
    sub _getParam {
        my ($self, $param) = @_;
        my $params = $self->_getParams;
        return $$params{$param};
    }

    # added for v0_07
    sub _getTopMenuObj {
        my ($self) = @_;
        my $params = $self->_getParams;
        my $obj = $$params{top_menu_obj};
        return $obj;
    }

    # added for v0_07
    sub _hasSetOpenAll {
        my ($self) = @_;
        my $top_menu_obj = $self->_getTopMenuObj;
        return undef unless $top_menu_obj;

        return $top_menu_obj->hasParamSetOpenAll;
    }

    ###########
    # utilities

=pod

=head2 Utilities

=head2 my $encoded = $info->urlEncode($plain_text)

 URL encodes the given string.  This does full url-encoding, so a
 space is %20, not a '+'.

=cut
    sub urlEncode {
        my ($self, $str) = @_;

        $str =~ s|([^A-Za-z0-9_])|sprintf("%%%02x", ord($1))|eg;

        return $str;
    }
    *url_encode = \&urlEncode;

=pod

=head2 my $query = $info->urlEncodeVars($var_hash)

 Takes a hash containing key/value pairs and returns a
 url-encoded query string appropriate for adding to the end of a
 url.  If a value is an array, it is assumed to be a multivalued
 input field and is added to the query string as such.

 If you want to encode the query stirng in the new style
 recommended by the W3C (use a semicolon as a separator in place
 of ampersand), pass a true value for the new_style_url parameter
 when creating the HTML::Menu::Hierarchical object.  This will
 become the default in a later release.

=cut
    sub urlEncodeVars {
        my ($self, $hash) = @_;
        my $string;
        my $var;
        my $vars = [ keys %$hash ];
        my @pairs;

        foreach $var (@$vars) {
            my $value = $$hash{$var};
            if (ref($value) eq 'ARRAY') {
                my $name = $self->urlEncode($var);
                foreach my $val (@$value) {
                    push(@pairs, $name . "=" . $self->urlEncode($val));
                }
            } else {
                push(@pairs, $self->urlEncode($var) . "=" . $self->urlEncode($$hash{$var}));
            }
        }

        return join($self->_getUrlSeparator, @pairs);
    }
    *url_encode_vars = \&urlEncodeVars;

=pod

=head2 my $plain_text = $info->urlDecode($url_enc_str)

 Decodes the given url-encoded string.

=cut
    sub urlDecode {
        my ($self, $str) = @_;

        $str =~ tr/+/ /;
        $str =~ s|%([A-Fa-f0-9]{2})|chr(hex($1))|eg;

        return $str;
    }
    *url_decode = \&urlDecode;

=pod

=head2 my $var_hash = $info->urlDecodeVars($url_enc_str)

 Decodes the url-encoded query string and returns a hash contain
 key/value pairs from the query string.  If a field appears more
 than once in the query string, it's value will be returned as a
 reference to an array of values.

=cut
    sub urlDecodeVars {
        my ($self, $query_string) = @_;
        my $pair;
        my $vars = {};

        foreach $pair (split /[;&]/, $query_string) {
            my ($name, $field) = map { $self->urlDecode($_) } split(/=/, $pair, 2);

            if (exists($$vars{$name})) {
                my $val = $$vars{$name};
                unless (ref($val) eq 'ARRAY') {
                    $val = [ $val ];
                    $$vars{$name} = $val;
                }
                push @$val, $field;
            } else {
                $$vars{$name} = $field;
            }
        }

        return wantarray ? %$vars : $vars;
    }
    *url_decode_vars = \&urlDecodeVars;

    sub _getUrlSeparator {
        my ($self) = @_;
        if ($self->_getParam('old_style_url')) {
            return '&';
        } elsif ($self->_getParam('new_style_url')) {
            return ';';
        } else {
            return '&';
        }
    }

=pod

=head2 my $modified_url = $info->addArgsToUrl($url, $var_hash)

 Takes the key/value pairs in $var_hash and tacks them onto the
 end of $url as a query string.

=cut
    sub addArgsToUrl {
        my ($self, $url, $args) = @_;
        
        if ($url =~ /\?/) {
            $url .= $self->_getUrlSeparator unless $url =~ /\?$/;
        } else {
            $url .= '?';
        }

        my $arg_str;
        if (ref($args) eq 'HASH') {
            $arg_str = $self->urlEncodeVars($args);
        } else {
            $arg_str = $args;
        }

        $url .= $arg_str;
        return $url;
    }
    *add_args_to_url = \&addArgsToUrl;

=pod

=head2 my $html = $info->escapeHtml($text)

 Escapes the given text so that it is not interpreted as HTML.

=cut

    sub escapeHtml {
        my ($self, $text) = @_;
        
        $text =~ s/\&/\&amp;/g;
        $text =~ s/</\&lt;/g;
        $text =~ s/>/\&gt;/g;
        $text =~ s/\"/\&quot;/g;
        $text =~ s/\$/\&dol;/g;

        return $text;
    }
    *escape_html = \&escapeHtml;

=pod

=head2 my $text = $info->unescapeHtml($html)

 Unescape the escaped text.

=cut
    
    sub unescapeHtml {
        my ($self, $text) = @_;
        $text =~ s/\&amp;/\&/g;
        $text =~ s/\&lt;/</g;
        $text =~ s/\&gt;/>/g;
        $text =~ s/\&quot;/\"/g;
        $text =~ s/\&dol;/\$/g;

        return $text;
    }
    *unescape_html = \&unescapeHtml;

    sub AUTOLOAD {
        my $self = shift;
        
        my $method = $AUTOLOAD;
        $method =~ s/^.*::([^:]+)$/$1/;

        if ($method =~ /^get(.+)$/) {
            my $str = $1;
            if ($str =~ /_/) {
                $str =~ s/^_//;
                return $self->getInfo()->{$str};
            } elsif ($str =~ /^[A-Z]/) {
                $str = lcfirst($str);
                $str =~ s/([A-Z])/_\L$1/g;

                my $info = $self->getInfo;
                return $info->{$str} if $info;
                return undef;
            } else {
                return "invalid name";
            }
        }

        return "undefined method $method";
    }

}

1;

__END__

=pod

=head2 There are also underscore_separated versions of these methods.

 E.g., unescapeHtml($html) becomes unescape_html($html)

=head1 TODO

 hasChildrenDisplayed() - tell whether or not the current item's
                          children will be displayed

=head1 BUGS

 Please send bug reports/feature requests to don@owensnet.com.

=head1 AUTHOR

 Don Owens <don@owensnet.com>

=head1 COPYRIGHT

 Copyright (c) 2003 Don Owens

 All rights reserved. This program is free software; you can
 redistribute it and/or modify it under the same terms as Perl
 itself.

=head1 VERSION

 $Id: ItemInfo.pm,v 1.30 2005/06/16 15:03:00 don Exp $

=cut

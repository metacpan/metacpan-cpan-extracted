# -*-perl-*-
# Creation date: 2003-01-05 20:35:53
# Authors: Don
# Change log:
# $Id: Hierarchical.pm,v 1.45 2005/06/16 15:31:03 don Exp $
#
# Copyright (c) 2003 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

=pod

=head1 NAME

 HTML::Menu::Hierarchical - HTML Hierarchical Menu Generator

=head1 SYNOPSIS

 my $menu_obj =
     HTML::Menu::Hierarchical->new($conf, \&callback, $params);

 my $html = $menu_obj->generateMenu($menu_item);

 or

 my $menu_obj =
     HTML::Menu::Hierarchical->new($conf, [ $obj, $method ]);

 my $html = $menu_obj->generateMenu($menu_item);

 or

 my $menu_obj =
     HTML::Menu::Hierarchical->new($conf, $std_callback_name);

 my $html = $menu_obj->generateMenu($menu_item);

 In the first case, the callback is a function.  In the second,
 the callback is a method called on the given object.  In the
 third example, the callback is the name of a standard callback
 defined by HTML::Menu::Hierarchical itself (see the section on
 callback functions/methods).

 The $conf parameter is a navigation configuration data structure
 (described below).

 The $params parameter is an optional hash reference containing
 parameters pertaining to the menu as a whole.  Recognized
 parameters are:

=over 4

=item first_with_url

 If this is set to a true value and you are using the 'url'
 field in the info hash (see below) in the configuration to
 specify the url for the menu item, then if a menu item is
 chosen that does not have a url configured, the url for that
 menu item will be changed to the url of the first child menu
 item that has a url configured.  This works by looking at the
 items first child, then at that child's first child, and so
 on.  It does not look at the second child.

=item open_all

 This has the same effect as the open_all parameter in the
 menu configuration structure mentioned below, except that it
 affects the entire menu hierarchy.

=item old_style_url

 When using the utilities urlEncodeVars() and addArgsToUrl(),
 this parameter controls which separator is used to separate
 key/value pairs in the generated query string.  Setting
 old_style_url to a true value will cause an ampersand ('&')
 to be used as the separator.

=item new_style_url

 When using the utilities urlEncodeVars() and addArgsToUrl(),
 this parameter controls which separator is used to separate
 key/value pairs in the generated query string.  Setting
 new_style_url to a true value will cause a semicolon (';') to
 be used as the separator, as recommended by the W3C.  This
 will become the default in a later release.

=back

=head1 DESCRIPTION

 HTML::Menu::Hierarchical provides a way to easily generate a
 hierarchical HTML menu without forcing a specific layout.
 All output is provided by your own callbacks (subroutine
 refs) and your own navigation configuration.

=head2 configuration data structure

 A navigation configuration is a reference to an array whose
 elements are hashrefs.  Each hash contains configuration
 information for one menu item and its children, if any.
 Consider the following example:

 my $conf = [
             { name => 'top_button_1',
               info => { text => 'Top Level Button 1',
                         url => '/'
                       },
               open => 1, # force this item's children to be displayed
               children => [
                            { name => 'button_1_level_2',
                              info => { text => "Child 1 of Button 1",
                                        url => '/child1.cgi'
                                      },
                            },
                            ]
             },

             { name => 'top_button_2',
               info => { text => 'Top Level Button 2',
                         url => '/top2.cgi'
                       },
               callback => [ $obj, 'my_callback' ]
             },
                
            ];

 In each hash, the 'name' parameter should correspond to the
 $menu_item parameter passed to the generateMenu() method.  This
 is how the module computes which menu item is selected.  This is
 generally passed via a CGI parameter, which can be tacked onto
 the end of the url in your callback function.  Note that this
 parameter must be unique among all the array entries.
 Otherwise, the module will not be able to decide which menu item
 is selected.

 The value of the 'info' parameter is available to your callback
 function via the getInfo() method called on the
 HTML::Menu::Hierarchical::ItemInfo object passed to the callback
 function.  In the above example, the 'info' parameter contains
 text to be displayed as the menu item, and a url the user is
 sent to when clicking on the menu item.

 The 'children' parameter is a reference to another array
 containing configuration information for child menu items.  This
 is where the Hierarchical part comes in.  There is no limit to
 depth of the hierarchy (until you run out of RAM, anyway).

 If a 'callback' parameter is specified that callback will be
 used for that menu item instead of the global callback passed to
 new().

 An 'open' parameter can be specified to force an item's children
 to be displayed.  This can be a scalar value that indicates true
 or false.  Or it can be a subroutine reference that returns a
 true or false value.  It can also be an array, in which case the
 first element is expected to be an object, the second element
 the name of a method to call on that object, and the rest of the
 elements will be passed as arguments to the method.  If an
 'open_all' parameter is passed, the current item and all items
 under it in the hierarchy will be forced open.

=head2 callback functions/methods

 Callback functions are passed a single parameter: an
 HTML::Menu::Hierarchical::ItemInfo object.  See the
 documentation on this object for available methods.  The
 callback function should return the HTML necessary for the
 corresponding menu item.

=cut

use strict;
use Carp;

{   package HTML::Menu::Hierarchical;

    use vars qw($VERSION);
    BEGIN {
        $VERSION = '0.13'; # update below in POD as well
    }

    use HTML::Menu::Hierarchical::Item;
    use HTML::Menu::Hierarchical::ItemInfo;

=pod

=head1 METHODS

=head2 new()

    my $menu_obj = HTML::Menu::Hierarchical->new($conf, \&callback);

=cut

    sub new {
        my ($proto, $menu_config, $iterator_sub, $params) = @_;
        my $self = bless { _open_list => {} }, ref($proto) || $proto;
        $self->setConfig($self->_convertConfig($menu_config));
        $self->setIterator($iterator_sub);
        $self->_setParams($params);
        return $self;
    }

    # for version v0_09
    sub _getOpenList {
        my ($self, $key) = @_;
        my $list = $$self{_open_list}{$key};
        return $list if $list;

        $list = $self->generateOpenList($key);
        $list = [] unless $list;
        $$self{_open_list}{$key} = $list;

        return $list;
    }

=pod

=head2 generateMenu($menu_item)
    
 my $html = $menu_obj->generateMenu($menu_item);

 $menu_item is the 'name' parameter of the selected item,
 typically passed as a CGI parameter.

=cut

    sub generateMenu {
        my ($self, $key) = @_;

        my $str;
        my $items = $self->generateOpenList($key);
        foreach my $item (@$items) {
            $str .= $self->_generateMenuSection($item);
        }

        $self->_cleanUpOpenlist($items);
        
        return $str;
    }
    *generate_menu = \&generateMenu;

=pod

=head2 addChildConf($conf, $menu_item_name)

 Adds another configuration tree into the current configuration
 at the specified node (name of the menu item).

=cut
    # added for v0_02
    sub addChildConf {
        my ($self, $conf, $menu_item) = @_;

        return undef unless $conf;

        my $selected_item = $self->getSelectedItem($menu_item);
        return undef unless $selected_item;

        my $converted_conf = $self->_convertConfig($conf);
        $selected_item->setChildren($converted_conf);

        return 1;
    }
    *add_child_conf = \&addChildConf;

=pod

=head2 addChildConfToChildren($conf, $menu_item_name)

 Like addChildConf(), except add this conf to the list of
 children of the parent with name $menu_item_name.  If $conf is
 an array, each element of the array will be added to the list of
 children.

=cut
    sub addChildConfToChildren {
        my ($self, $conf, $menu_item) = @_;
        
        return undef unless $conf;

        my $selected_item = $self->getSelectedItem($menu_item);
        return undef unless $selected_item;

        my $converted_conf;
        if (UNIVERSAL::isa($conf, 'ARRAY')) {
            $converted_conf = $self->_convertConfig($conf);
        } else {
            $converted_conf = $self->_convertConfig([ $conf ]);
        }
        $selected_item->addChild($converted_conf);

        return 1;
    }
    *add_child_conf_to_children = \&addChildConfToChildren;

# =pod

# =head2 getSelectedItem($menu_item)

#  Returns the Item object corresponding to the selected menu
#  item.

# =cut
    sub getSelectedItem {
        my ($self, $key) = @_;
        my $path = $self->findSelectedPath($self->getConfig, $key);
        return undef unless $path;
        return pop(@$path);
    }

#     sub getSelectedItem {
#         my ($self, $key) = @_;
#         my $open_list = $self->_getOpenList($key);
#         if (@$open_list) {
#             return $$open_list[0]->getSelectedItem();
#         }
#     }

=pod

=head2 getSelectedItemInfo($menu_item)

 Returns the ItemInfo object corresponding to the selected menu
 item.

=cut
    sub getSelectedItemInfo {
        my ($self, $key) = @_;
        my $path = $self->getSelectedPath($key);
        if (UNIVERSAL::isa($path, 'ARRAY') and @$path) {
            return $path->[$#$path];
        }
    }
    *get_selected_item_info = \&getSelectedItemInfo;

=pod

=head2 getSelectedPath($menu_item)

 Returns an array of InfoItem objects representing the path from
 the top level menu item to the selected menu item.

=cut
    # added for v0_09
    sub getSelectedPath {
        my ($self, $key) = @_;
        my $open_list = $self->_getOpenList($key);
        return [] unless @$open_list;

        # take the path of Item objects and from that map out the
        # list of ItemInfo objects.
        my $item_path = $$open_list[0]->_getSelectedPath;

        my %open_map = map { ($_->getName, $_) } @$open_list;
        my @selected_path = map { $open_map{$_->getName} } @$item_path;
        return \@selected_path;
    }
    *get_selected_path = \&getSelectedPath;

    sub generateOpenList {
        my ($self, $key) = @_;
        my $params = $self->_getParams;

        $self->_fixupConf;
        
        if ($$params{first_with_url}) {
            my $non_url_items = $self->_getNonUrlItems;
            my $new_name = $$non_url_items{$key};
            $key = $new_name unless $new_name eq '';
        }

        
        my $conf = $self->getConfig;
        return '' unless $conf;

        my $selected_path = $self->findSelectedPath($conf, $key);
        my $list = [];
        foreach my $item (@$conf) {
            my $l = $self->_generateOpenList($item, $key, $selected_path, 0);
            push @$list, @$l;
        }

        my $last_item;
        foreach my $item (@$list) {
            if ($last_item) {
                $item->setPreviousItem($last_item);
                $last_item->setNextItem($item);
            }

            $last_item = $item;
        }

        return $list;
    }

    # cleans up circular references in the open list so perl will
    # deallocate the memory used
    sub _cleanUpOpenlist {
        my ($self, $list) = @_;

        foreach my $item (@$list) {
            $item->setPreviousItem(undef);
            $item->setNextItem(undef);
        }
    }

    sub _generateOpenList {
        my ($self, $item, $key, $selected_path, $level, $parent) = @_;
        my $new_level = $level + 1;
        my $list = [];

        my $hier_params = $self->_getParams;
        my $params = { top_menu_obj => $self,
                       old_style_url => $$hier_params{old_style_url},
                       new_style_url => $$hier_params{new_style_url},
                       std_callback_params => $$hier_params{std_callback_params},
                     };
        my $info_obj = HTML::Menu::Hierarchical::ItemInfo->new($item, $selected_path, $key,
                                                               $parent, $params);
        
        $info_obj->setLevel($level);
        push @$list, $info_obj;

        if ($info_obj->isOpen and $info_obj->hasChildren) {
            foreach my $child (@{$item->getChildren}) {
                my $l = $self->_generateOpenList($child, $key, $selected_path, $new_level,
                                                $info_obj);
                push @$list, @$l;
            }
        }
        
        return $list;
    }
    
    sub _generateMenuSection {
        my ($self, $info_obj) = @_;
        
        my $str;
        my $iterator = $info_obj->getOtherField('callback');
        $iterator = $self->getIterator unless $iterator;
        
        if (ref($iterator) eq 'ARRAY') {
            my ($obj, $meth) = @$iterator;
            $str .= $obj->$meth($info_obj);
        } elsif (not ref($iterator)) {
            # string - use standard callback method
            my $meth = "_stdCallback" . $iterator;
            $str .= $self->$meth($info_obj);
        } else {
            $str .= $iterator->($info_obj);
        }
        
        return $str;
    }

    # added for v0_07
    sub _addToItemsWithoutUrl {
        my ($self, $name, $new_url) = @_;
        my $non_url_items = $self->_getNonUrlItems;
        $$non_url_items{$name} = $new_url;
    }
    
    # added for v0_07
    sub _getNonUrlItems {
        my ($self) = @_;
        my $items = $$self{_non_url_items};
        unless ($items) {
            $items = {};
            $$self{_non_url_items} = $items;
        }
        return $items;
    }

    # added for v0_07
    sub _checkFirstUrl {
        my ($self, $item) = @_;
        my $info = $item->getInfo;
        return undef unless $$info{url} eq '';

        my ($url, $new_name) = $self->_findFirstUrlFromChild($item);
        return undef if $url eq '';
        
        my %new_info = %$info;
        $new_info{url} = $url;
        $item->setInfo(\%new_info);
        $self->_addToItemsWithoutUrl($item->getName, $new_name);

        return $url;
    }
    
    # added for v0_07
    sub _findFirstUrlFromChild {
        my ($self, $item) = @_;

        my $children = $item->getChildren;
        unless ($children and @$children) {
            return wantarray ? ('', '') : '';
        }

        my $first_child = $$children[0];
        my $info = $first_child->getInfo;
        my $url = $$info{url};

        unless ($url eq '') {
            return ($url, $first_child->getName);
        }

        return $self->_findFirstUrlFromChild($first_child);
    }
    
    # added for v0_07
    # Makes any adjustments necessary to the configuration
    sub _fixupConf {
        my ($self, $conf) = @_;
        my $params = $self->_getParams;
        return undef unless $$params{first_with_url};
        
        $conf = $self->getConfig unless $conf;
        return undef unless $conf;

        foreach my $item (@$conf) {
            $self->_checkFirstUrl($item) if $$params{first_with_url};
            
            my $children = $item->getChildren;
            if ($children and @$children) {
                $self->_fixupConf($children);
            }
        }        
    }

    sub findSelectedPath {
        my ($self, $conf, $key) = @_;
        return undef unless $conf;

        my $params = $self->_getParams;
        foreach my $item (@$conf) {
            if ($item->getName eq $key) {
                return [ $item ];
            }
            my $path = $self->findSelectedPath($item->getChildren, $key);
            if ($path) {
                unshift @$path, $item;
                return $path;
            }
        }
        
        return undef;
    }

    sub _convertConfig {
        my ($self, $conf) = @_;
        
        my $obj_array = [];
        foreach my $item (@$conf) {
            if (ref($item) eq 'HTML::Menu::Hierarchical::Item') {
                push @$obj_array, $item;
                next;
            }
            my $children;
            if (my $new_conf = $$item{children}) {
                $children = $self->_convertConfig($new_conf);
            }
            my $item = HTML::Menu::Hierarchical::Item->new(@$item{'name', 'info'}, $children,
                                                          $item);
            push @$obj_array, $item;
        }

        return $obj_array;
    }
    
    #####################
    # getters and setters
    
    sub getConfig {
        my ($self) = @_;
        return $$self{_menu_config};
    }
    
    sub setConfig {
        my ($self, $conf) = @_;
        $$self{_menu_config} = $conf;
    }

    sub getIterator {
        my ($self) = @_;
        return $$self{_iterator};
    }
    
    sub setIterator {
        my ($self, $iterator) = @_;
        $$self{_iterator} = $iterator;
    }

    # added for v0_07
    sub _getParams {
        my ($self) = @_;
        my $params = $$self{_params};
        $params = {} unless $params;
        return $params;
    }

    sub _setParams {
        my ($self, $params) = @_;
        $$self{_params} = $params;
    }

    # added for v0_07
    sub hasParamSetOpenAll {
        my ($self) = @_;
        my $params = $self->_getParams;
        if ($$params{open_all}) {
            return 1;
        }

        return undef;
    }

    sub _stdCallbackUl1 {
        my ($self, $info_obj) = @_;

        my $html = '';
        my $level = $info_obj->getLevel;
        my $text = $info_obj->getText;
        my $name = $info_obj->getName;
        my $info = $info_obj->getInfo;
        
        my $params = $info_obj->getStandardCallbackParams;
        my $cgi_var_name = $$params{menu_item_param_name} || 'm_i';
        
        my $url = $info_obj->addArgsToUrl($info_obj->getUrl, { $cgi_var_name => $name });
    
        if ($level == 0 and $info_obj->isFirstDisplayed) {
            my $style = qq{style="padding-left: 0em; margin-left: 1em"};
            if (exists($$info{list_class})) {
                $style = qq{class="$$info{list_class}"};
            } elsif (exists($$params{list_class})) {
                $style = qq{class="$$params{list_class}"};
            }
            $html .= qq{<ul $style>\n};
        } elsif ($info_obj->isFirstSiblingDisplayed) { # new in version 0.12
            my $style = qq{style="padding-left: 0em; margin-left: 1em"};
            if (exists($$info{list_class})) {
                $style = qq{class="$$info{list_class}"};
            } elsif (exists($$params{list_class})) {
                $style = qq{class="$$params{list_class}"};
            }

            $html .= "  " x ($level + 1);
            $html .= qq{<ul $style>\n};
        }

        $html .= "  " x ($level == 0 ? $level + 1 : $level + 2);
        $html .= qq{<li>\n};
    
        my $link_style = qq{style="text-decoration: none};
        $link_style .= qq{; font-family: arial, helvetica, sans-serif};
        $link_style .= qq{; font-size: 12pt; font-weight: bold; color: #626262"};

        if (exists($$info{link_class})) {
            $link_style = qq{class="$$info{link_class}"};
        } elsif (exists($$params{link_class})) {
            $link_style = qq{class="$$params{link_class}"};            
        }
    
        $html .= "  " x ($level == 0 ? $level + 2 : $level + 3);
        $html .= qq{<a $link_style href="$url">$text</a>\n};
        unless ($info_obj->isOpen) {
            $html .= "  " x ($level == 0 ? $level + 1 : $level + 2);
            $html .= qq{</li>\n};
        }

        if ($info_obj->isLastSiblingDisplayed and not $info_obj->hasChildren) {
            $html .= "  " x ($level + 1) unless $level == 0;
            $html .= qq{</ul>\n};
            $html .= "  " x ($level) . qq{</li>\n};
        }
        if ($info_obj->isLastDisplayed) {
            $html .= "  " x ($level + 1) unless $level == 0;
            $html .= qq{</ul>\n};
        }

        return $html;
    }

    sub _stdCallbackCiscoExt {
        my ($self, $info_obj) = @_;

        my $info = $info_obj->getInfo;
        my $level = $info_obj->getLevel;
        my $selected_level = $info_obj->getSelectedLevel;
        my $params = $info_obj->getStandardCallbackParams;

        my $name = $info_obj->getName;

        my $image_uri = '';
        
        my $cgi_var_name = $$params{menu_item_param_name} || 'm_i';
        my $url = $info_obj->addArgsToUrl($info_obj->getUrl, { $cgi_var_name => $name });

        my $parent_bg_color = '#669999';
        my $selected_bg_color = '#ffffff';
        my $child_bg_color = '#cccccc';
        my $peer_bg_color = '#999999';
        my $architecture_bg_color = '#336666';
        my $divider_color = '#003333';
        
        my $text_class = 'hinavparent';
        my $text_color = '#ffffff';
        my $text_bg_color = $parent_bg_color;

        my $child_indent = 9;
        my $indent = 0;

        if ($level == $selected_level) {
            $text_class = 'hinavpeer';
            $text_color = '#000000';
            if ($info_obj->isSelected) {
                $text_bg_color = $selected_bg_color;
            } elsif ($level == 1) {
                $text_color = '#ffffff';
                $text_bg_color = $parent_bg_color;
            } else {
                $text_bg_color = $peer_bg_color;
            }
        } elsif ($level < $selected_level) {
            $text_class = 'hinavparent';
            $text_color = '#ffffff';
            if ($selected_level - $level == 1) {
                $text_bg_color = $parent_bg_color;
            } else {
                $text_bg_color = $architecture_bg_color;
            }
        } else {
            # $level > $selected_level
            $text_class = 'hinavchild';
            $text_color = '#000000';
            $text_bg_color = $child_bg_color;
        }
        
        if ($text_class eq 'hinavchild') {
            $indent = $child_indent if $level > 1;
        }
        
        if ($info_obj->isSelected) {
            $text_bg_color = $selected_bg_color;
            $text_color = '#000000';
        }

        my $text = '';
        if ($text_class =~ /parent/) {
            $text = $info_obj->escapeHtml(uc($$info{text}));
        } else {
            $text = $info_obj->escapeHtml($$info{text});
        }

        my $plus = $image_uri . 'hinav_l0plus.gif';
        if ($level) {
            if ($text_class =~ /parent/) {
                $plus = $image_uri . 'hinav_plusrev.gif';
            } else {
                $plus = $image_uri . 'hinav_plus.gif';
            }
        }

        my $spacer = $image_uri . 's.gif';
        my $html = '';
        if ($level == 0) {
            $html .= qq{<tr>\n};
            $html .= qq{<td bgcolor="$architecture_bg_color">};
            $html .= qq{<img src="$spacer" border="0" height="15" width="17" /></td>};
            $html .= qq{<td colspan="2" bgcolor="$architecture_bg_color">};
            $html .= qq{<a href="$url" class="$text_class">$text</a></td>};
            $html .= qq{<td bgcolor="$architecture_bg_color" valign="top">};
            $html .= qq{<img src="$plus" border="0" /></td>\n};
            $html .= qq{</tr\n};

            $html .= qq{<tr>\n};
            $html .= qq{<td colspan="4" bgcolor="$divider_color">};
            $html .= qq{<img src="$spacer" border="0" /></td>};
            $html .= qq{</tr>\n};
            return $html;
        }

        my $left_image = $image_uri . 's.gif';

        my $link = qq{<span class="$text_class"><a href="$url" class="$text_class">};
        $link .= qq{<font color="$text_color">$text</a></span>};

        $html .= qq{<tr>\n};
        $html .= qq{<td bgcolor="$text_bg_color">};
        $html .= qq{<img src="$left_image" border="0" height="15" width="17" /></td>};
        $html .= qq{<td colspan="2" bgcolor="$text_bg_color">$link</td>};

        $html .= qq{<td bgcolor="$text_bg_color">};

        if ($info_obj->hasChildren and not $info_obj->isOpen) {
            $html .= qq{<img src="$plus" border="0" />};
        } else {
            $html .= qq{&nbsp;};
        }
        
        $html .= qq{</td>\n</tr>\n};

        $html .= qq{<tr>\n};
        $html .= qq{<td colspan="4" bgcolor="$divider_color">};
        $html .= qq{<img src="$spacer" border="0" /></td>};
        $html .= qq{</tr>\n};
        
        
        return $html;
    }

    # added for v0_09
    sub DESTROY {
        my ($self) = @_;
        my $list_hash = $$self{_open_list};
        if ($list_hash) {
            while (my ($key, $list) = each %$list_hash) {
                $self->_cleanUpOpenlist($list);
            }
        }
    }


}

1;

__END__

=pod

=head2 There are also underscore_separated versions of these methods.

 E.g., unescapeHtml($html) becomes unescape_html($html)

=head1 EXAMPLES

 See the scripts in the examples subdirectory for example usages.

 See the documentation for HTML::Menu::Hierarchical::ItemInfo for
 methods available via the $info_obj parameter passed to the
 menu_callback function below.

=over 4

sub menu_callback {
    my ($info_obj) = @_;
    my $info_hash = $info_obj->getInfo;
    my $level = $info_obj->getLevel;

    my $text = $$info_hash{text};
    $text = '&nbsp;' if $text eq '';
    my $item_arg = $info_obj->getName;

    # Add a cgi parameter m_i to url so we know which menu
    # item was chosen
    my $url = $info_obj->addArgsToUrl($$info_hash{url},
                                      { m_i => $item_arg });

    my $dpy_text = $info_obj->isSelected ? "&lt;$text&gt" : $text;
    my $spacer = '&nbsp;&nbsp;' x $level;
    my $str = qq{<tr>\n};
    $str .= qq{<td bgcolor="#cccc88"><a href="$url">};
    $str .= $spacer . $dpy_text;
    $str .= qq{</a></td>};
    $str .= qq{</tr>\n};
    return $str;
}


=back

=head1 BUGS

 Please send bug reports/feature requests to don@owensnet.com.

 There are currently no checks for loops in the configuration
 data structure passed to the module.

=head1 AUTHOR

 Don Owens <don@owensnet.com>

=head1 COPYRIGHT

 Copyright (c) 2003 Don Owens

 All rights reserved. This program is free software; you can
 redistribute it and/or modify it under the same terms as Perl
 itself.

=head1 VERSION

 0.13

=cut

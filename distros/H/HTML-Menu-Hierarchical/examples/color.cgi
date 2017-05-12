#!/usr/bin/perl

# Creation date: 2003-02-25 23:10:40
# Authors: Don
# Change log:
# $Id: color.cgi,v 1.1 2003/03/03 06:05:09 don Exp $

use strict;
use CGI;
use Carp;

# main
{
    local($SIG{__DIE__}) = sub { local(*STDERR) = *STDOUT;
                                 print "Content-Type: text/plain\n\n";
                                 &Carp::cluck(); exit 0 };


    use HTML::Menu::Hierarchical;
    my $cgi = CGI->new;
    my $fields = $cgi->Vars;
    
    my $conf = &get_conf();
    my $menu_obj = HTML::Menu::Hierarchical->new($conf, \&menu_callback);

    # pass in the m_i CGI parameter to tell us which menu item is selected
    my $menu = $menu_obj->generateMenu($$fields{m_i});
    
    my $html;

    print "Content-Type: text/html\n\n";

    $html .= qq{<table border="0" cellpadding="2" cellspacing="2">\n};
    $html .= $menu;
    $html .= qq{</table>\n};

    print $html;
}

exit 0;

###############################################################################
# Subroutines

sub get_conf {
    my $script = $ENV{SCRIPT_NAME}; # self referring url
    my $conf = [
                { name => 'top_button_1',
                  info => { text => 'Top Level Button 1',
                            url => $script
                          },
                  children => [
                               { name => 'button_1_level_2',
                                 info => { text => "Child 1 of Button 1",
                                           url => $script
                                         },
                                 children => [
                                              { name => 'button_1_level_2_child1',
                                                info => { text => "Child 1 of level 2 button 1",
                                                          url => $script
                                                        },
                                              }
                                             ],
                               },

                              ]
                },

                { name => 'top_button_2',
                  info => { text => 'Top Level Button 2',
                            url => $script
                          }
                },
                

               ];

    return $conf;
}

sub menu_callback {
    my ($info_obj) = @_;
    my $info_hash = $info_obj->getInfo;
    my $level = $info_obj->getLevel;

    my $text = $$info_hash{text};
    $text = '&nbsp;' if $text eq '';

    my $url = $$info_hash{url};

    my $item_arg = $info_obj->getName;

    # Add a cgi parameter m_i to url so we know which menu item was chosen
    $url = $info_obj->addArgsToUrl($url, { m_i => $item_arg });

    my $str;

    my $top_bg_color = "#8888aa";
    my $selected_bg_color = "#e2e2e2";
    my $child_bg_color = "#a2a2a2";
    my $peer_child_bg_color = "#b2b2b2";

    my $bg_color = $top_bg_color;

    my $next_is_selected;
    my $next_obj = $info_obj->getNextItem;
    if ($next_obj) {
        $next_is_selected = $next_obj->isSelected;
    }

    my $global_style = qq{text-decoration: none; font-family: Arial, Helvetica, sans-serif;};
    $global_style .= qq{ font-size: 12pt; font-weight: normal};
    my $style = qq{style="color: #ffffff; $global_style"};

    my $top_bottom_color = "#666699";
    if ($level == 0) {
        my $top = qq{<tr>\n};
        $top .= qq{<td bgcolor="$top_bottom_color" width="100">};
        $top .= qq{<a href="$url" $style><span style="$style">$text</span></a></td>};
        $top .= qq{</tr>\n};
        $str .= $top;
        return $str;
    }

    my $max_dpy_level = $info_obj->getMaxDisplayedLevel;
    my $bg_color;

    my $selected_item = $info_obj->getSelectedItem();
    if ($level == 1) {
        $bg_color = $top_bg_color;
        $style = qq{style="color: #ffffff; $global_style"};
    } elsif ($max_dpy_level > 2) {
        if ($level == $info_obj->getSelectedLevel + 1) {
            $bg_color = $peer_child_bg_color;
            $style = qq{style="color: #000000; $global_style"};
        } elsif ($level == $info_obj->getSelectedLevel and not $selected_item->hasChildren) {
            $bg_color = $peer_child_bg_color;
            $style = qq{style="color: #000000; $global_style"};
        } elsif ($max_dpy_level - $level >= 2) {
            $bg_color = $top_bg_color;
            $style = qq{style="color: #ffffff; $global_style"};
        } else {
            $bg_color = $child_bg_color;
            $style = qq{style="color: #ffffff; $global_style"};
        }
    } elsif ($level == 2) {
        $bg_color = $child_bg_color;
        $style = qq{style="color: #ffffff; $global_style"};
    }

    if ($info_obj->isSelected) {
        $bg_color = $selected_bg_color;
        $style = qq{style="color: #000000; $global_style"};
    }

    $str .= qq{<tr>\n};
    $str .= qq{<td bgcolor="$bg_color">};
    $str .= qq{<a href="$url" $style><span $style>$text</span></a></td>};

    $str .= qq{</tr>\n};


    return $str;
}

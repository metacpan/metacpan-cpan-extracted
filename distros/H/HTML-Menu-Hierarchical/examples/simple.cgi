#!/usr/bin/perl

# Creation date: 2003-02-25 23:10:40
# Authors: Don
# Change log:
# $Id: simple.cgi,v 1.3 2003/03/03 06:33:24 don Exp $

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

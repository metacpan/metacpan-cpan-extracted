package HTML::PopupTreeSelect::Dynamic;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.2';

use base 'HTML::PopupTreeSelect';
use Carp qw(croak);

# template source files, included at the bottom
our $TEMPLATE_SRC;
our $NODE_TEMPLATE_SRC;

# override new() to setup defaults for dynamic_url and dynamic_params
sub new {
    my ($pkg, %args) = @_;
    my $self = $pkg->SUPER::new(%args);

    if ($self->{dynamic_url}) {
        # quote literal URL
        $self->{dynamic_url} = qq{"$self->{dynamic_url}"};
    } else {
        # setup default
        $self->{dynamic_url} = q{window.location};
    }

    $self->{dynamic_params} ||= "";

    $self->{include_prototype} = 1 unless defined $self->{include_prototype};

    return $self;
}

# override output to drive the dynamic template
sub output {
    my ($self, $template) = @_;
    $template ||= HTML::Template->new(scalarref          => \$TEMPLATE_SRC,
                                      die_on_bad_params => 0,
                                      global_vars       => 1,
                                     );
    if( $self->{include_prototype} ) {
        eval { require HTML::Prototype };
        croak "requires HTML::Prototype unless 'include_prototype' option is fase"
            if( $@ );
        my $prototype = HTML::Prototype->new();
        my $js = $prototype->define_javascript_functions;
        $template->param(prototype_js => $js);
    }

    # setup template parameters
    my %param = map { ($_, $self->{$_}) } qw(name height width 
                                             indent_width onselect
                                             form_field form_field_form
                                             button_label
                                             button_image title 
                                             include_css resizable
                                             image_path scrollbars
                                             hide_selects hide_textareas
                                             dynamic_url dynamic_params
                                            );

    # get output for the widget
    $template->param(%param);
    return $template->output;
}

# handle 
sub handle_get_node {
    my ($self, %args) = @_;
    my $query = $args{query};
    croak("Missing required parameter 'query'.") unless $query;

    my $id    = $query->param('id');
    my $data  = $self->{data};
    my $node  = $data;

    my $template = HTML::Template->new(scalarref        => \$NODE_TEMPLATE_SRC,
                                       global_vars      => 1,
                                       die_on_bad_params => 0);

    my @node_loop;
    if (not defined $id) {
        # return the root (handle multiple roots if an array ref)
        if( ref $data eq 'ARRAY' ) {
            my $count = 0;
            @node_loop = map {  $self->_output_node($_, $count++) } (@$data);
        } elsif( ref $data eq 'HASH' ) {
            @node_loop = ( $self->_output_node($data, "0") );
        }
    } else {
        # return the children of this node
        my $parent;
        if( ref $data eq 'ARRAY' ) {
            $parent   = $self->_find_node($data, $id);
        } elsif( ref $data eq 'HASH' ) {
            $parent   = $self->_find_node($data->children, $id);
        }
        my $child_id = 0;
        foreach my $node (@{$parent->{children}}) {
            push(@node_loop, $self->_output_node($node, "$id/$child_id"));
            $child_id++;
        }
    }
    $template->param(node_loop => \@node_loop);

    # setup global template parameters
    my %param = map { ($_, $self->{$_}) } qw(name height width 
                                             indent_width onselect
                                             form_field form_field_form
                                             button_label
                                             button_image title 
                                             include_css resizable
                                             image_path scrollbars
                                             hide_selects hide_textareas
                                             dynamic_url dynamic_params
                                            );
    $template->param(\%param);

    return $template->output();
}

sub _find_node {
    my ($self, $data, $id) = @_;

    # if it's a single digit, then it's a leaf
    if( $id =~ /^\d+$/ ) {
        return $data->[$id];
    } else {
        # recurse down a level
        my ($car, $cdr) = split('/', $id, 2);
        return $self->_find_node($data->[$car]->{children}, $cdr);
    }
}
 
sub _output_node {
    my ($self, $node, $id) = @_;

    # setup template data for a single node
    my %param = (label       => $node->{label},
                 value       => $node->{value},
                 id          => $id,
                 open        => $node->{open} ? 1 : 0,
                 inactive    => $node->{inactive} ? 1 : 0);

    if ($node->{children} and @{$node->{children}}) {
        $param{has_children} = 1;
    }
    
    return \%param;
}

$TEMPLATE_SRC = <<END;
<tmpl_if include_css><style type="text/css"><!--

  /* style for the box around the widget */
  .hpts-outer {
     visibility:       hidden;
     position:         absolute;
     top:              0px;
     left:             0px;
     border:           2px outset #333333;
     background-color: #ffffff;
     filter:           progid:DXImageTransform.Microsoft.dropShadow( Color=bababa,offx=3,offy=3,positive=true);
  }

  /* style for the box that contains the tree */
  .hpts-inner {
<tmpl_if scrollbars>
     overflow:         scroll;
</tmpl_if>
     width:            <tmpl_var width>px;
<tmpl_if height>
     height:           <tmpl_var height>px;
</tmpl_if>
  }

  /* title bar style.  The width here will define a minimum width for
     the widget. */
  .hpts-title {
     padding:          2px;
     margin-bottom:    4px;     
     font-size:        large;
     color:            #ffffff;
     background-color: #666666;
     width:            <tmpl_var width>px;
  }

  /* style of a block of child nodes - indents them under their parent
     and starts them hidden */
  .hpts-block {
     margin-left:      24px;
     display:          none;
  }

  /* style for the button bar at the bottom of the widget */
  .hpts-bbar {
     padding:          3px;
     text-align:       right;
     margin-top:       10px;     
     background-color: #666666;
     width:            <tmpl_var width>px;
  }

  /* style for the buttons at the bottom of the widget */
  .hpts-button {
     margin-left:      15px;
     background-color: #ffffff;
     color:            #000000;
  }

  /* style for selected labels */
  .hpts-label-selected {
     background:       #98ccfe;
  }

  /* style for labels after being unselected */
  .hpts-label-unselected {
     background:       #ffffff;
  }

  /* style for bottom bar used for resizing */
  .hpts-botbar {
      background-color: #666666;
      width:            <tmpl_var width>px;
      font-size:        7px;
      padding:          3px;
  }

--></style></tmpl_if>

<script type="text/javascript">
<!--
  /* record location of mouse on each click */
  var hpts_mouseX;
  var hpts_mouseY;
  var hpts_offsetX;
  var hpts_offsetY;
  var hpts_locked_titlebar;  /* for moving */
  var hpts_locked_botbar;  /* for resizing */
  var hpts_curr_width = <tmpl_if width><tmpl_var width><tmpl_else>225</tmpl_if>;
  var hpts_curr_height = <tmpl_if height><tmpl_var height><tmpl_else>200</tmpl_if>;

  hpts_lock = function(evt) {
        evt = (evt) ? evt : event;
        hpts_set_locked(evt);
        hpts_update_mouse(evt);

        if (hpts_locked_titlebar) {
            if (evt.pageX) {
               hpts_offsetX = evt.pageX - ((hpts_locked_titlebar.offsetLeft) ? 
                              hpts_locked_titlebar.offsetLeft : hpts_locked_titlebar.left);
               hpts_offsetY = evt.pageY - ((hpts_locked_titlebar.offsetTop) ? 
                              hpts_locked_titlebar.offsetTop : hpts_locked_titlebar.top);
            } else if (evt.offsetX || evt.offsetY) {
               hpts_offsetX = evt.offsetX - ((evt.offsetX < -2) ? 
                              0 : document.body.scrollLeft);
               hpts_offsetY = evt.offsetY - ((evt.offsetY < -2) ? 
                              0 : document.body.scrollTop);
            } else if (evt.clientX) {
               hpts_offsetX = evt.clientX - ((hpts_locked_titlebar.offsetLeft) ? 
                              hpts_locked_titlebar.offsetLeft : 0);
               hpts_offsetY = evt.clientY - ((hpts_locked_titlebar.offsetTop) ? 
                               hpts_locked_titlebar.offsetTop : 0);
            }
            return false;
        }

        if (hpts_locked_botbar) {
            if (evt.pageX) {
               hpts_offsetX = evt.pageX;
               hpts_offsetY = evt.pageY;
            } else if (evt.clientX) {
               hpts_offsetX = evt.clientX;
               hpts_offsetY = evt.clientY;
            } else if (evt.offsetX || evt.offsetY) {
               hpts_offsetX = evt.offsetX - ((evt.offsetX < -2) ? 
                              0 : document.body.scrollLeft);
               hpts_offsetY = evt.offsetY - ((evt.offsetY < -2) ? 
                              0 : document.body.scrollTop);
            }            
            return false;
        }

        return true;
  }

  hpts_update_mouse = function(evt) {
      if (evt.pageX) {
         hpts_mouseX = evt.pageX;
         hpts_mouseY = evt.pageY;
      } else {
         hpts_mouseX = evt.clientX + document.documentElement.scrollLeft + document.body.scrollLeft;
         hpts_mouseY = evt.clientY + document.documentElement.scrollTop  + document.body.scrollTop;
      }
  }


  hpts_set_locked = function(evt) {
    var target = (evt.target) ? evt.target : evt.srcElement;
    if (target && target.className == "hpts-title") { 
       hpts_locked_titlebar = target.parentNode;
       return;
    } else if (target && target.className == "hpts-botbar") {
       hpts_locked_botbar = target.parentNode;
       return;
    }
    hpts_locked_titlebar = null;
    hpts_locked_botbar = null;
    return;
  }

  hpts_drag = function(evt) {
        evt = (evt) ? evt : event;
        hpts_update_mouse(evt);
        var titleobj = document.getElementById("<tmpl_var name>-title");
        var innerobj = document.getElementById("<tmpl_var name>-inner");
        var bbarobj = document.getElementById("<tmpl_var name>-bbar");
        var botbarobj = document.getElementById("<tmpl_var name>-botbar");

        if (hpts_locked_titlebar) {
           hpts_locked_titlebar.style.left = (hpts_mouseX - hpts_offsetX) + "px";
           hpts_locked_titlebar.style.top  = (hpts_mouseY - hpts_offsetY) + "px";
           evt.cancelBubble = true;
           return false;
        }

        if (hpts_locked_botbar) {           
           titleobj.style.width = (hpts_curr_width + hpts_mouseX - hpts_offsetX) + "px";
           innerobj.style.width = (hpts_curr_width + hpts_mouseX - hpts_offsetX) + "px";
           bbarobj.style.width = (hpts_curr_width + hpts_mouseX - hpts_offsetX) + "px";
           botbarobj.style.width = (hpts_curr_width + hpts_mouseX - hpts_offsetX) + "px";
           innerobj.style.height  = (hpts_curr_height + hpts_mouseY - hpts_offsetY) + "px";
           evt.cancelBubble = true;
           return false;
        }
  }

  hpts_release = function(evt) {
     hpts_locked_titlebar = null;
     if (hpts_locked_botbar){
     var widthstr = document.getElementById("<tmpl_var name>-inner").style.width;
     var heightstr = document.getElementById("<tmpl_var name>-inner").style.height;
     hpts_curr_width = parseFloat(widthstr.substr(0,widthstr.indexOf("px")));
     hpts_curr_height = parseFloat(heightstr.substr(0,heightstr.indexOf("px")));
     }
     hpts_locked_botbar = null;
  }

  document.onmousedown = hpts_lock;
  document.onmousemove = hpts_drag;
  document.onmouseup   = hpts_release;

  var <tmpl_var name>_selected_id = -1;
  var <tmpl_var name>_selected_val;
  var <tmpl_var name>_selected_elem;

  /* expand or collapse a sub-tree */
  <tmpl_var name>_toggle_expand = function(id) {
     var obj = document.getElementById("<tmpl_var name>-desc-" + id);
     var plus = document.getElementById("<tmpl_var name>-plus-" + id);
     var node = document.getElementById("<tmpl_var name>-node-" + id);
     if (obj.style.display != 'block') {
        obj.style.display = 'block';
        plus.src = "<tmpl_var image_path>minus.png";
        node.src = "<tmpl_var image_path>open_node.png";

        new Ajax.Updater("<tmpl_var name>-desc-" + id, <tmpl_var dynamic_url>, { method: 'get', parameters: "<tmpl_if dynamic_params><tmpl_var dynamic_params>&</tmpl_if>id=" + id, evalScripts: true });
     } else {
        obj.style.display = 'none';
        obj.innerHTTML    = '';
        plus.src = "<tmpl_var image_path>plus.png";
        node.src = "<tmpl_var image_path>closed_node.png";
     }
  }

  /* select or unselect a node */
  <tmpl_var name>_toggle_select = function(id, val) {
     if (<tmpl_var name>_selected_id != -1) {
        /* turn off old selected value */
        var old = document.getElementById("<tmpl_var name>-line-" + <tmpl_var name>_selected_id);
        old.className = "hpts-label-unselected";
     }

     if (id == <tmpl_var name>_selected_id) {
        /* clicked twice, turn it off and go back to nothing selected */
        <tmpl_var name>_selected_id = -1;
     } else {
        /* turn on selected item */
        var new_obj = document.getElementById("<tmpl_var name>-line-" + id);
        new_obj.className = "hpts-label-selected";
        <tmpl_var name>_selected_id = id;
        <tmpl_var name>_selected_val = val;
     }
  }

  /* it's showtime! */
  <tmpl_var name>_show = function() {
        document.getElementById("<tmpl_var name>-inner").innerHTML = '';
        new Ajax.Updater('<tmpl_var name>-inner', <tmpl_var dynamic_url>, { method: 'get', parameters: "<tmpl_var dynamic_params>", evalScripts: true  });

        var obj = document.getElementById("<tmpl_var name>-outer");
        var x = Math.floor(hpts_mouseX - (hpts_curr_width/2));
        x = (x > 2 ? x : 2);
        var y = Math.floor(hpts_mouseY - (hpts_curr_height/5 * 4));
        y = (y > 2 ? y : 2);

        obj.style.left = x + "px";
        obj.style.top  = y + "px";
        obj.style.visibility = "visible";

      <tmpl_if hide_selects>
        for(var f = 0; f < document.forms.length; f++) {
          for(var x = 0; x < document.forms[f].elements.length; x++) {
             var e = document.forms[f].elements[x];
             if (e.options) {
                e.style.visibility = "hidden";
             }
          }
        }
     </tmpl_if>

      <tmpl_if hide_textareas>
        for(var f = 0; f < document.forms.length; f++) {
          for(var x = 0; x < document.forms[f].elements.length; x++) {
             var e = document.forms[f].elements[x];
             if (e.rows) {
                e.style.visibility = "hidden";
             }
          }
        }
     </tmpl_if>
  }

  /* user clicks the ok button */
  <tmpl_var name>_ok = function() {
        if (<tmpl_var name>_selected_id == -1) {
           alert("Please select an item or click Cancel to cancel selection.");
           return;
        }

        /* fill in a form field if they spec'd one */
        <tmpl_if form_field><tmpl_if form_field_form>document.forms["<tmpl_var form_field_form>"]<tmpl_else>document.forms[0]</tmpl_if>.elements["<tmpl_var form_field>"].value = <tmpl_var name>_selected_val;</tmpl_if>

        /* trigger onselect */
        <tmpl_if onselect><tmpl_var onselect>(<tmpl_var name>_selected_val)</tmpl_if>
         
        <tmpl_var name>_close();
  }

  <tmpl_var name>_cancel = function() {
        <tmpl_var name>_close();
  }

  <tmpl_var name>_close  = function() {
        /* hide window */
        var obj = document.getElementById("<tmpl_var name>-outer");
        obj.style.visibility = "hidden";         

        /* clear selection */
        if (<tmpl_var name>_selected_id != -1) {
                <tmpl_var name>_toggle_select(<tmpl_var name>_selected_id);
        }

      <tmpl_if hide_selects>
        for(var f = 0; f < document.forms.length; f++) {
          for(var x = 0; x < document.forms[f].elements.length; x++) {
             var e = document.forms[f].elements[x];
             if (e.options) {
                e.style.visibility = "visible";
             }
          }
        }
      </tmpl_if>

      <tmpl_if hide_textareas>
        for(var f = 0; f < document.forms.length; f++) {
          for(var x = 0; x < document.forms[f].elements.length; x++) {
             var e = document.forms[f].elements[x];
             if (e.rows) {
                e.style.visibility = "visible";
             }
          }
        }
      </tmpl_if>
  }
  //-->
</script>

<tmpl_var prototype_js>

<div id="<tmpl_var name>-outer" class="hpts-outer">
  <div class="hpts-title" id="<tmpl_var name>-title"><tmpl_var title></div>
  <div class="hpts-inner" id="<tmpl_var name>-inner"></div>
  <div class="hpts-bbar" id="<tmpl_var name>-bbar" style="white-space:nowrap">
    <input class="hpts-button" type="button" value=" Ok " onclick="<tmpl_var name>_ok()">
    <input class="hpts-button" type="button" value="Cancel" onclick="<tmpl_var name>_cancel()">
  </div>
<tmpl_if resizable>  <div id="<tmpl_var name>-botbar" class="hpts-botbar">&nbsp;</div></tmpl_if>
</div>

<input class="hpts-button" type="button" value="<tmpl_var button_label>" onmouseup="<tmpl_var name>_show()">
END

$NODE_TEMPLATE_SRC = <<END;
<tmpl_loop node_loop>
    <div style="white-space:nowrap">
        <tmpl_if has_children>
           <img alt="" id="<tmpl_var name>-plus-<tmpl_var id>" width=16 height=16 src="<tmpl_var image_path>plus.png" onclick="<tmpl_var name>_toggle_expand('<tmpl_var id>')"><span id="<tmpl_var name>-line-<tmpl_var id>" <tmpl_unless inactive>ondblclick="<tmpl_var name>_toggle_expand('<tmpl_var id>')" onclick="<tmpl_var name>_toggle_select('<tmpl_var id>', '<tmpl_var escape=html value>')"</tmpl_unless>>
        <tmpl_else>
            <img alt="" width=16 height=16 src="<tmpl_var image_path>L.png"><span id="<tmpl_var name>-line-<tmpl_var id>" <tmpl_unless inactive>onclick="<tmpl_var name>_toggle_select('<tmpl_var id>', '<tmpl_var escape=html value>')"</tmpl_unless>>
        </tmpl_if>
        <img id="<tmpl_var name>-node-<tmpl_var id>" width=16 height=16 src="<tmpl_var image_path>closed_node.png" alt="">
        <tmpl_unless inactive><a href="javascript:void(0);"></tmpl_unless><tmpl_var label><tmpl_unless inactive></a></tmpl_unless>
       </span>
   </div>
   <tmpl_if has_children>
       <div id="<tmpl_var name>-desc-<tmpl_var id>" class="hpts-block" style="white-space: nowrap; display: none"></div>
   </tmpl_if>
   <tmpl_if open><script language="javascript"><tmpl_var name>_toggle_expand('<tmpl_var id>')</script></tmpl_if>
</tmpl_loop>
END


1;
__END__

=head1 NAME

HTML::PopupTreeSelect::Dynamic - dynamic version of HTML::PopupTreeSelect

=head1 SYNOPSIS

This module is used just like HTML::PopupTreeSelect, with the addition
of 3 new parameters - C<dynamic_url>, C<dynamic_params> and C<include_prototype>.  Here's
a full example:

  use HTML::PopupTreeSelect::Dynamic;

  # setup your tree as a hash structure.  This one sets up a tree like:
  # 
  # - Root
  #   - Top Category 1
  #      - Sub Category 1
  #      - Sub Category 2
  #   - Top Category 2

  my $data = { label    => "Root",
               value    => 0,              
               children => [
                            { label    => "Top Category 1",
                              value    => 1,
                              children => [
                                           { label => "Sub Category 1",
                                             value => 2
                                           },
                                           { label => "Sub Category 2",
                                             value => 3
                                           },
                                          ],
                            },
                            { label  => "Top Category 2",
                              value  => 4 
                            },
                           ]
              };


  # create your HTML tree select widget.  This one will call a
  # javascript function 'select_category(value)' when the user selects
  # a category.
  my $select = HTML::PopupTreeSelect::Dynamic->new(
                 name           => 'category',
                 data           => $data,
                 title          => 'Select a Category',
                 button_label   => 'Choose',
                 onselect       => 'select_category',
                 dynamic_params => 'rm=get_node');

  # include it in your HTML page, for example using HTML::Template:
  $template->param(category_select => $select->output);

A complete, and terribly coded, example of how to use this modules is
included in the module distribution.  Look for the file called
C<hpts_demo.cgi>.

=head1 DESCRIPTION

This module provides a dynamic version of
L<HTML::PopupTreeSelect|HTML::PopupTreeSelect>.  By dynamic I mean
that the tree is sent to the client in chunks as the user clicks
around the tree.  In L<HTML::PopupTreeSelect|HTML::PopupTreeSelect>
the entire tree is sent to the client when the page is loaded,
introducing a long delay for large trees.  With
L<HTML::PopupTreeSelect::Dynamic> trees of virtually any size can be
navigated without noticable delays.

=head1 CAVEATS

Be aware of the following issues, some or all of which may be fixed in
a future version:

=over

=item *

As you can see from the SYNOPSIS and INTERFACE sections no provision
for dynamically generating the tree data is present.  This means that
while the client gets data in chunks, the server code still needs to
compile the complete tree in memory to pass as the C<data> parameter
to new().  In general this is considerably less problematic than
sending the entire tree to the client, but it would be nice to remove
this potential bottleneck as well.

=item *

This module uses L<HTML::Prototype|HTML::Prototype> to provide AJAX
functionality.  This limits support to only those browsers supported
by the Prototype Javascript library.  Details concerning Prototype may
be found here:

   http://prototype.conio.net/

I have personally tested Firefox v1.0.2 on Linux and IE 6 on Windows
XP.

=item *

Although this module uses Prototype for the AJAX calls, it's still
using all the painfully hand-wrought dragging and tree-generation
code.  It would be nice to move this stuff over to Prototype, although
it seems like it would have little practical benefits.

=head1 INTERFACE

This module has the same interface as
L<HTML::PopupTreeSelect|HTML::PopupTreeSelect>, with a few additions:

=head2 additional new() param : dynamic_url (optional)

This option provides the URL which will be used for callbacks from the
widget to get node data.  For example:

  $select = HTML::PopupTreeSelect::Dynamic->new(
                dynamic_url => 'http://example.com/tree_select.cgi',
                ...);

This will cause the widget to make dynamic (AJAX) requests to
http://example.com/tree_select.cgi to request node data.  The code
running behind this URL should call handle_get_node(), shown below.

Defaults to the current URL of the running application, as determined
via Javascript's window.location method.

=head2 additional new() param : dynamic_params (optional)

This option provides additional parameters to be added to the request
to C<dynamic_url>.  These should be in URL format.  For example, to
set "rm" to "get_node":

    $select = HTML::PopupTreeSelect::Dynamic->new(
                dynamic_params => 'rm=get_node',
                ...);

=head2 additional new() param : include_prototype (optional)

This options surpress the output of the C<Prototype.js> that comes
from L<HTML::Prototype>. By default it is C<true>.

It is useful to set this option to C<false> when you are already using
F<prototype.js> in your templates via a C<< <script> >> tag.

=head2 handle_get_node()

This method must be called when your application recieves a request
using C<dynamic_url> and C<dynamic_params>.  A CGI.pm object
containing the data from this query must be passed as a named
parameter:

  $output = $select->handle_get_node(query => $query);

The return value is the output to be returned to browser.

=head1 BUGS

I know of no bugs in this module.  If you find one, please file a bug
report at:

  http://rt.cpan.org

Alternately you can email me directly at C<sam@tregar.com>.  Please
include the version of the module and a complete test case that
demonstrates the bug.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Sam Tregar

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=head1 AUTHOR

Sam Tregar <sam@tregar.com>

=cut


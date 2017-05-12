package HTML::PopupTreeSelect;
use 5.006;
use strict;
use warnings;

use Carp qw(croak);
use HTML::Template 2.6;

our $VERSION = "1.6";
our $TEMPLATE_SRC;

=head1 NAME

HTML::PopupTreeSelect - HTML popup tree widget

=head1 SYNOPSIS

  use HTML::PopupTreeSelect;

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
  my $select = HTML::PopupTreeSelect->new(name         => 'category',
                                          data         => $data,
                                          title        => 'Select a Category',
                                          button_label => 'Choose',
                                          onselect     => 'select_category');

  # include it in your HTML page, for example using HTML::Template:
  $template->param(category_select => $select->output);

=head1 DESCRIPTION

This module creates an HTML popup tree selector.  The HTML and
Javascript produced will work in Mozilla 1+ (Netscape 6+) on all
operating systems, Microsoft IE 5+ and Safari 1.0.  For an example,
visit this page:

  http://sam.tregar.com/html-popuptreeselect/example.html

I based the design for this widget on the xTree widget from WebFX.
You can find it here:

  http://webfx.eae.net/dhtml/xtree/

This module is used to provide the category chooser in Krang, an open
source content management system.  You can find out more about Krang
here:

  http://krang.sf.net

=head1 INSTALLATION

To use this module you'll need to copy the contents of the images/
directory in the module distribution into a place where your webserver
can serve them.  If that's not the same place your CGI will run from
then you need to set the image_path parameter when you call new().
See below for details.

=head1 INTERFACE

=head2 new()

new(), is used to build a new HTML selector.  You call it with a
description of the tree to display and get back an object.  Call it
with following parameters:

=over

=item name

A unique name for the tree selector.  You can have multiple tree
selectors on a page, but they must have unique names.  Must be
alpha-numeric and begin with a letter.

=item data

This must be a hash reference (or an array reference of these hash
references, if there are multiple "root" categories) containing
the following keys:

=over

=item label (required)

The textual label for this node.

=item value (required)

The value passed to the onselect handler or set in the form_field when
the user selects this node.

=item open (optional)

If set to 1 this node will start open (showing its children).  By
default all nodes start closed.

=item inactive (optional)

If set to 1 this node will not be selectable.  It will not appear as a
link in the widget and clicking on the label will have no effect.
However, if it has children they will still be accessible.

=item children (optional)

The 'children' key may point to an array of hashes with the same keys.
This is the tree structure which will be displayed in the tree
selector.

=back

See SYNOPSIS above for an example of a valid data structure.

=item title

The title of the window which pops up.

=item button_label (optional)

The widget pops up when the user presses a button. This field gives
the label for the button.  Defaults to "Choose".

=item onselect (optional)

Specifies a Javascript function that will be called when an item in
the tree is selected.  Recieves the value of the item as a single
argument.  The default is for nothing to happen.

=item form_field (optional)

Specifies a form field to recieve the value of the selected item.
This provides a no-javascript means to use this widget (although the
widget itself, of course, uses great gobs of javascript).

=item form_field_form (optional)

Specifies the form in which to find the C<form_field> specified.  If
 not included the first form on the page will be used.

=item include_css (optional)

Set this to 0 and the default CSS will not be included in the widget
output.  This allows you to include your own CSS which will be used by
your widget.  Modifying the CSS will allow you to control the fonts,
colors and spacing in the output widget.

If you run the widget with include_css set to 1 then you can use that
output as a base on which to make changes.

=item resizable (optional)

Set this to 1 and the default widget output will not be resizable.  If 
you run the widget with resizable set to 1 then default output will
have a bar at the bottom which allows it to be resized by dragging.
Defaults to 0.

=item image_path (optional)

Set this to the URL to the images for the widget.  These files should
be copied from the images directory in the module distribution into a
place where your webserver can reach them.  By default this is empty
and the widget expects to find images in the current directory.

=item width (optional)

Set this to the width of the popup window.  Defaults to 200.

=item height (optional)

Set this to the height of the tree box inside the window.  This
defaults to 0 which allows the chooser to grow as the tree expands.
If you set this option you'll probably want to set the
C<use_scrollbars> option as well.

=item scrollbars (optional)

If set to 1 the chooser will have a fixed size (specified by width and
height) and show scrollbars inside the tree area.

=item hide_selects (optional)

This option will cause the chooser to dynamically hide select boxes on
the page when the chooser opens.  This is necessary in order to avoid
the select boxes showing through the chooser under Windows in both IE
and Mozilla (to a lesser extent).  This defaults to 1.  For a detailed
explanation of the problem, see this page:

   http://www.webreference.com/dhtml/diner/seethru/

=item hide_textareas (optional)

This option will cause the chooser to dynamically hide textareas on
the page when the chooser opens.  This is necessary to workaround a
bug in Netscape 6.0 through 7.0 in which buttons hovering over
textareas are not clickable.  This defect is fixed in version 7.1 and
later.  This option defaults to 0, since this problem only affects
older browsers.

=item parent_var (optional)

This option includes a 'parent' loop in the template data used to
construct the widget's HTML.  It's not used by the default template,
so it defaults to 0.  Set to 1 to use this variable in your own
template via sub-classing.

=back

=head1 output()

Call output() to get HTML from the widget object to include in your
page.

=cut

=head1 SUBCLASSING

HTML::PopupTreeSelect can be subclassed, for the purposes of -- for
example -- using a different template engine to generate the HTML.
Here's one brief example, using the Template engine:

   package My::PopupTreeSelect;
   use Template;
   use base 'HTML::PopupTreeSelect';

   sub output {
       my($self) = @_;
       return $self->SUPER::output(Template->new);
   }

   sub _output_generate {
       my($self, $template, $param) = @_;
       my $output;
       $template->process(\$MY_TEMPLATE_SRC, $param, \$output);
       return $output;
   }

Of course, $MY_TEMPLATE_SRC will need to be provided, too.
$HTML::PopupTreeSelect::TEMPLATE_SRC is a global variable,
so it may be modified to your liking, or your own template
data can be provided to your own template generator method.

=head1 CAVEATS

=over 4

=item *

The javascript used to implement the widget needs control over the
global document.onmousedown, document.onmousemove and
document.onmouseup handlers.  This means that it's unlikely to play
nice with other DHTML on the same page.

=back

=head1 TODO

Here are some possible directions for future development.  Send me a
patch for one of these and you're guaranteed a place in F<Changes>.

=over

=item *

Allow each node to specify its own icon.  Right now every node uses
C<closed_node.png> and C<open_node.png>.

=back

=head1 BUGS

I know of no bugs in this module.  If you find one, please file a bug
report at:

  http://rt.cpan.org

Alternately you can email me directly at C<sam@tregar.com>.  Please
include the version of the module and a complete test case that
demonstrates the bug.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003, 2004 Sam Tregar

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=head1 AUTHOR

Sam Tregar <sam@tregar.com>

=cut

sub new {
    my $pkg = shift;
    
    # setup defaults and get parameters
    my $self = bless({ button_label  => 'Choose',
                       height        => 0,
                       width         => 300,
                       scrollbars    => 0,
                       hide_selects  => 1,
                       hide_textareas=> 0,
                       indent_width  => 25,
                       include_css   => 1,
                       resizable     => 0,
                       image_path    => ".",
                       parent_var    => 0,
                       @_,
                     }, $pkg);
    
    # fix up image_path to always end in a /
    $self->{image_path} .= "/" unless $self->{image_path} =~ m!/$!;

    # check required params
    foreach my $req (qw(name data title)) {
        croak("Missing required parameter '$req'") unless exists $self->{$req};
    }

    return $self;
}

sub output {
    my($self, $template) = @_;
    $template ||= HTML::Template->new(scalarref          => \$TEMPLATE_SRC,
                                      die_on_bad_params => 0,
                                      global_vars       => 1,
                                     );

    # build node loop
    my @loop;
    $self->_output_node(node   => $self->{data},
                        loop   => \@loop,
                       );

    # setup template parameters
    my %param = (loop => \@loop,
                map { ($_, $self->{$_}) } qw(name height width 
                                             indent_width onselect
                                             form_field form_field_form
                                             button_label
                                             button_image title 
                                             include_css resizable
                                             image_path scrollbars
                                             hide_selects hide_textareas
                                            ));

    # get output for the widget
    my $output;
    if ($self->can('_output_generate')) {
        $output = $self->_output_generate($template, \%param);
    } else {
        $template->param(%param);
        $output = $template->output;
    }

    return $output;
}

# recursively add nodes to the output loop
sub _output_node {
    my ($self, %arg) = @_;

    my @nodes;
    if (ref $arg{node} eq 'ARRAY') {
        @nodes = @{$arg{node}};
    } else {
        @nodes = ($arg{node});
    }

    for my $node (@nodes) {
        my $id = next_id();

        push @{$arg{loop}}, { label       => $node->{label},
                              value       => $node->{value},
                              id          => $id,
                              open        => $node->{open} ? 1 : 0,
                              inactive    => $node->{inactive} ? 1 : 0,
                              ($self->{parent_var} ? 
                               (parent => [ $arg{parent} || () ]) : 
                               ()),
                            };
    
        if ($node->{children} and @{$node->{children}}) {
            $arg{loop}[-1]{has_children} = 1;
            for my $child (@{$node->{children}}) {
                $self->_output_node(node   => $child,
                                    parent => $node,
                                    loop   => $arg{loop},
                                   );
            }
            push @{$arg{loop}}, { end_block => 1 };
        }
    }
}

{ 
    my $id = 1;
    sub next_id { $id++ }
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

  document.onmousedown = hpts_lock;
  document.onmousemove = hpts_drag;
  document.onmouseup   = hpts_release;

  function hpts_lock(evt) {
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

  function hpts_update_mouse(evt) {
      if (evt.pageX) {
         hpts_mouseX = evt.pageX;
         hpts_mouseY = evt.pageY;
      } else {
         hpts_mouseX = evt.clientX + document.documentElement.scrollLeft + document.body.scrollLeft;
         hpts_mouseY = evt.clientY + document.documentElement.scrollTop  + document.body.scrollTop;
      }
  }


  function hpts_set_locked(evt) {
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

  function hpts_drag(evt) {
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

  function hpts_release(evt) {
     hpts_locked_titlebar = null;
     if (hpts_locked_botbar){
     var widthstr = document.getElementById("<tmpl_var name>-inner").style.width;
     var heightstr = document.getElementById("<tmpl_var name>-inner").style.height;
     hpts_curr_width = parseFloat(widthstr.substr(0,widthstr.indexOf("px")));
     hpts_curr_height = parseFloat(heightstr.substr(0,heightstr.indexOf("px")));
     }
     hpts_locked_botbar = null;
  }

  var <tmpl_var name>_selected_id = -1;
  var <tmpl_var name>_selected_val;
  var <tmpl_var name>_selected_elem;

  /* expand or collapse a sub-tree */
  function <tmpl_var name>_toggle_expand(id) {
     var obj = document.getElementById("<tmpl_var name>-desc-" + id);
     var plus = document.getElementById("<tmpl_var name>-plus-" + id);
     var node = document.getElementById("<tmpl_var name>-node-" + id);
     if (obj.style.display != 'block') {
        obj.style.display = 'block';
        plus.src = "<tmpl_var image_path>minus.png";
        node.src = "<tmpl_var image_path>open_node.png";
     } else {
        obj.style.display = 'none';
        plus.src = "<tmpl_var image_path>plus.png";
        node.src = "<tmpl_var image_path>closed_node.png";
     }
  }

  /* select or unselect a node */
  function <tmpl_var name>_toggle_select(id, val) {
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
  function <tmpl_var name>_show() {
        var obj = document.getElementById("<tmpl_var name>-outer");
        var x = Math.floor(hpts_mouseX - (hpts_curr_width/2));
        x = (x > 2 ? x : 2);
        var y = Math.floor(hpts_mouseY - (hpts_curr_height/5 * 4));
        y = (y > 2 ? y : 2);

        document.getElementById('<tmpl_var name>-inner').style.overflow = 'auto'; /*hack FF(OS X)*/

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
  function <tmpl_var name>_ok() {
        if (<tmpl_var name>_selected_id == -1) {
           /* ahomosezwha? */
           alert("Please select an item or click Cancel to cancel selection.");
           return;
        }

        /* fill in a form field if they spec'd one */
        <tmpl_if form_field><tmpl_if form_field_form>document.forms["<tmpl_var form_field_form>"]<tmpl_else>document.forms[0]</tmpl_if>.elements["<tmpl_var form_field>"].value = <tmpl_var name>_selected_val;</tmpl_if>

        /* trigger onselect */
        <tmpl_if onselect><tmpl_var onselect>(<tmpl_var name>_selected_val)</tmpl_if>
         
        <tmpl_var name>_close();
  }

  function <tmpl_var name>_cancel() {
        <tmpl_var name>_close();
  }

  function <tmpl_var name>_close () {
        document.getElementById('<tmpl_var name>-inner').style.overflow = 'hidden'; /*hack FF(OS X)*/

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

<div id="<tmpl_var name>-outer" class="hpts-outer">
  <div class="hpts-title" id="<tmpl_var name>-title"><tmpl_var title></div>
  <div class="hpts-inner" id="<tmpl_var name>-inner">
  <tmpl_loop loop>
    <tmpl_unless end_block>
       <div style="white-space:nowrap">
          <tmpl_if has_children>
              <img alt="" id="<tmpl_var name>-plus-<tmpl_var id>" width=16 height=16 src="<tmpl_var image_path><tmpl_if open>minus<tmpl_else>plus</tmpl_if>.png" onclick="<tmpl_var name>_toggle_expand(<tmpl_var id>)"><span id="<tmpl_var name>-line-<tmpl_var id>" <tmpl_unless inactive>ondblclick="<tmpl_var name>_toggle_expand(<tmpl_var id>)" onclick="<tmpl_var name>_toggle_select(<tmpl_var id>, '<tmpl_var escape=html value>')"</tmpl_unless>>
          <tmpl_else>
              <img alt="" width=16 height=16 src="<tmpl_var image_path>L.png"><span id="<tmpl_var name>-line-<tmpl_var id>" <tmpl_unless inactive>onclick="<tmpl_var name>_toggle_select(<tmpl_var id>, '<tmpl_var escape=html value>')"</tmpl_unless>>
          </tmpl_if>
                 <img id="<tmpl_var name>-node-<tmpl_var id>" width=16 height=16 src="<tmpl_var image_path>closed_node.png" alt="">
                 <tmpl_unless inactive><a href="javascript:void(0);"></tmpl_unless><tmpl_var label><tmpl_unless inactive></a></tmpl_unless>
             </span>
       </div>
       <tmpl_if has_children>
          <div id="<tmpl_var name>-desc-<tmpl_var id>" class="hpts-block" style="white-space: nowrap; display: <tmpl_if open>block<tmpl_else>none</tmpl_if>">
       </tmpl_if>
    <tmpl_else>
      </div>
    </tmpl_unless>
  </tmpl_loop>
  </div>
  <div class="hpts-bbar" id="<tmpl_var name>-bbar" style="white-space:nowrap">
    <input class="hpts-button" type="button" value=" Ok " onclick="<tmpl_var name>_ok()">
    <input class="hpts-button" type="button" value="Cancel" onclick="<tmpl_var name>_cancel()">
  </div>
<tmpl_if resizable>  <div id="<tmpl_var name>-botbar" class="hpts-botbar">&nbsp;</div></tmpl_if>
</div>

<input class="hpts-button" type="button" value="<tmpl_var button_label>" onmouseup="<tmpl_var name>_show()">
END

1;

%#----------------------------------------------------------------------------
%# File: editviewbutton
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# dont_list
%#----------------------------------------------------------------------------
<%method dont_list>
<%perl>
  
  # if this method exists, this brick name will not be returned by 
  # HTML::Bricks::get_bricks_list

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render_edit
%#----------------------------------------------------------------------------
<%method render_edit>

This button contols whether or not bricks is in edit or view mode.  There
is nothing to edit here.

</%method>
 
%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  if (defined $$rARGS{mode}) { 
    $HTML::Bricks::session{mode} = $$rARGS{mode};
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render
%#----------------------------------------------------------------------------
<%method render>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode) = @_;

  if ($HTML::Bricks::session{mode} eq 'edit') {
    $mode = 'view';
  }
  else {
    $mode = 'edit';
  }

</%perl>
  <a class="authorbar" href="<% $uri %><% $route_tag %>:mode=<% $mode %>"><% $mode %></a>
</%method>

%#----------------------------------------------------------------------------
%# File: text
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# render_edit
%#----------------------------------------------------------------------------
<%method render_edit>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  use Apache::Util;

  my $rdata = $$rbrick{data};

</%perl>
<form method="post" action="<% $$ruri %>">
  <input type="submit" value="update">
  <input type="reset" value="reset">
  <br>
  <textarea name="<% $route_tag %>:data" cols="80" rows="40"><% Apache::Util::escape_html($$rdata{text}) %></textarea>
</form>
</%method>
 
%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};

  if ($mode eq 'edit') {
    if ($$rARGS{fn} eq 'edit') {
      $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect); }
    }
    elsif (defined $$rARGS{data}) {
      $$rdata{text} = $$rARGS{data};
      $rparent_brick->set_modified();
    }
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render
%#----------------------------------------------------------------------------
<%method render>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode) = @_;
  my $rdata = $$rbrick{data};
</%perl>

  <% $$rdata{text} %>
</%method>

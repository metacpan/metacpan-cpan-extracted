%#----------------------------------------------------------------------------
%# File: statichtml
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};
  my @time_data = localtime(time);
  my $curryear = $time_data[5] + 1900; 

  $$rdata{dpy_cright} = $types[0];
  $$rdata{dpy_cent} =   'checked';
  $$rdata{start_year} = $curryear;

</%perl>
</%method> 

%#----------------------------------------------------------------------------
%# render_edit
%#----------------------------------------------------------------------------
<%method render_edit>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};

  my $checked_dpy_cent = (defined $$rdata{dpy_cent}) ? 'checked' : '';

</%perl>
<b>copyright properties</b>
<form method="post" action="<% $$ruri %>">
  <input type="hidden" name="<% $route_tag %>:edit_props" value="1">

  Select copyright type:<br>

% for (my $i = 0; $i <= $#types; $i++) {
%   my $sel = ($$rdata{dpy_cright} eq $types[$i]) ? 'checked' : '';
    <input type="radio" name="<% $route_tag %>:dpy_cright" value="<% $i %>" <% $sel %>><% $types[$i] %>
    <br>
% }
  
  <br>
  <input type="checkbox" name="<% $route_tag %>:dpy_cent" <% $checked_dpy_cent %>>
  display century indicator (20nn) on current year
  <br>
  start year: <input type="text" name="<% $route_tag %>:start_year" value="<% $$rdata{start_year} %>" size="4">
  <p>
  <input type="submit" value="update">
  <input type="reset" value="reset">
  <br>

</form>
</%method>
 
%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  if ($mode eq 'edit') {
    if ($$rARGS{fn} eq 'edit') {
      $$rredirect = sub { $rbrick->render_edit($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
    }
    elsif (defined $$rARGS{edit_props}) {
      my $rdata = $$rbrick{data};
    
      $$rdata{dpy_cright} = $types[$$rARGS{dpy_cright}];
      $$rdata{dpy_cent} = $$rARGS{dpy_cent};
      $$rdata{start_year} = $$rARGS{start_year};
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

  $m->out($$rdata{dpy_cright});

  my @time_data = localtime(time);
  my $curryear = $time_data[5] + 1900; 
  
  $m->out($$rdata{start_year} . '-') unless ($curryear == $$rdata{start_year});

  $m->out(substr($curryear,0,2)) unless !defined $$rdata{dpy_cent};
  $m->out(substr($curryear,2,2));

</%perl>
</%method>

%#----------------------------------------------------------------------------
<%shared>

  my @types = ('copyright&nbsp;&copy;&nbsp;',
               'Copyright&nbsp;&copy;&nbsp;',
               'COPYRIGHT&nbsp;&copy;&nbsp;',
               '&copy;&nbsp;');

</%shared>

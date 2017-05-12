%#----------------------------------------------------------------------------
%# File: useraccess
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# render_edit
%#----------------------------------------------------------------------------
<%method render_edit>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;
</%perl>

  <b>useraccess properties</b>
  <p>
  There is nothing to edit here
</%method>
 
%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  if (defined $$rARGS{submit}) {

    use HTML::Bricks::Users;
    my $usermgr = HTML::Bricks::Users->new();

    my $ruser = $usermgr->get($$rARGS{username});

    if (crypt($$rARGS{password}, $$ruser{password}) eq $$ruser{password}) {

      use Apache::Session::File;
      my %session;

      eval {
        tie %session, 'Apache::Session::File', undef, {
          Directory => '/tmp',
          LockDirectory => '/tmp'
        };
      };

      $HTML::Bricks::session_id = $session{_session_id};
      %HTML::Bricks::session = %session;
      $HTML::Bricks::session{username} = $$rARGS{username};
    }
    else {
      print STDERR "bad username, password combo\n";
    }
  }
  elsif (defined $$rARGS{logout}) {
    HTML::Bricks::set_logout();
  }

  if ($mode eq 'edit') {
    if ($$rARGS{fn} eq 'edit') {
      $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };
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

</%perl>
% if (!defined $HTML::Bricks::session{username}) {
  <table border="0">
    <form method="post" action="<% $uri %>">
      <tr>
        <td align="right">
          name
        </td>
        <td>	 
          <input type="text" name="<% $route_tag %>:username" size="10">
        </td>
      </tr>
      <tr>
        <td align="right">
          password
        </td>
        <td>
          <input type="password" name="<% $route_tag %>:password" size="10">
        </td>
      </tr>
      <tr>
        <td align="right" colspan="2">
          <input type="submit" name="<% $route_tag %>:submit" value="login">
        </td>
      </tr>
    </form>
  </table>
% } else {
  <a class="authorbar" href="<% $uri %><% $route_tag %>:logout=1">logout</a>
% }
</%method>

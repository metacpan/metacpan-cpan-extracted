%#---------------------------------------------------------------------
%# File: mappings
%#---------------------------------------------------------------------

%#---------------------------------------------------------------------
%# render_edit
%#---------------------------------------------------------------------
<%method render_edit>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $r = Apache->request;

  my $rassemblies = HTML::Bricks::get_assemblies_list(); 
  my $rm;

  use HTML::Bricks::Mappings;
  my $mapper = HTML::Bricks::Mappings->new();

  my $rary = $mapper->get_list();

  if (!defined $$rARGS{position}) {
    $$rm{folder} = '/';
    $$rm{recurse} = 'no';
    $$rm{match_type} = 'string';
    $$rm{match_string} = 'index.html';
    $$rm{brick_name} = $$rassemblies[0]; 
  }
  else {
    $rm = $$rary[$$rARGS{position}];
  }

  my ($no_sel, $yes_sel);
  if ($$rm{recurse} eq 'no') {
    $no_sel = 'selected';
  }
  else {
    $yes_sel = 'selected';
  }

  my ($string_sel, $regexp_sel);
  if ($$rm{match_type} eq 'string') {
    $string_sel = 'selected';
  }
  else {
    $regexp_sel = 'selected';
  }

</%perl>
<b>edit mapping</b>
<p>

<form method="post" action="<% $$ruri %>">
% if (defined $$rARGS{position}) {
  <input type="hidden" name="<% $route_tag %>:position" value="<% $$rARGS{position} %>">
% }
  <table border="0">
    <tr>
      <td align="center">
        URI starts with (folder)
      </td>
      <td align="center">
        URI ends with
      </td>
    </tr>
    <tr>
      <td> 
        <input type="text" name="<% $route_tag %>:folder" value="<% $$rm{folder} %>">
%#        <input type="submit" name="<% $route_tag %>:select_folder" value="select">

        <select name="<% $route_tag %>:recurse">
          <option value="n" <% $no_sel %>>don't recurse
          <option value="y" <% $yes_sel %>>recurse
        </select>
        &nbsp;&nbsp;&nbsp;
      </td>
      <td>
        &nbsp;&nbsp;&nbsp;
        <input type="text" name="<% $route_tag %>:match_string" value="<% $$rm{match_string} %>">
        <select name="<% $route_tag %>:match_type">
          <option value="string" <% $string_sel %>>string
          <option value="regexp" <% $regexp_sel %>>Perl regexp
        </select>
      </td>
    </tr>
  </table>
  <br>
  maps to assembly
  <select name="<% $route_tag %>:brick_name">
%   foreach (@$rassemblies) {
%     next if $_ eq 'assembly';
%     my $sel = ($_ eq $$rm{brick_name}) ? ' selected' : '';
      <option value="<% $_ %>"<% $sel %>><% $_ %>
%   }
  </select>
  <p>
  <input type="reset" value="reset">
  <input type="submit" name="<% $route_tag %>:submit" value="go">
</form>
</%method>

%#---------------------------------------------------------------------
%# process
%#---------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  return if !defined $HTML::Bricks::session_id;

  my $r = Apache->request;
  
  use HTML::Bricks::Mappings;
  my $mapper = HTML::Bricks::Mappings->new();
  my $rary = $mapper->get_list();

  if ($$rARGS{op} eq 'new') {
    $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect); }
  } 
  elsif ($$rARGS{op} eq 'edit') {
    $$rARGS{position} = $$rARGS{source};
    $$rARGS{position} = $$rARGS{dest} if $$rARGS{source} eq '';
    $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect); }
  }
  elsif ($$rARGS{op} eq 'move') {
    my $src = $$rARGS{source};
    my $dest = $$rARGS{dest};

    return if (!defined $src) || (!defined $dest);

    $dest-- if ($src < $dest);
 
    $rary = $mapper->read_mappings();
 
    my $rm = splice @$rary, $src, 1;
    splice @$rary, $dest, 0, $rm;

    $mapper->write_mappings($rary);
  }
  elsif ($$rARGS{op} eq 'delete') {
    my $src = $$rARGS{source};
    $src = $$rARGS{dest} if $src eq '';

    return if (!defined $src);

    $rary = $mapper->read_mappings();
    
    splice @$rary, $src, 1;  

    $mapper->write_mappings($rary);
  }
  elsif ($$rARGS{submit} eq 'go') {
    my %mapping;

    $mapping{folder} = $$rARGS{folder};
    $mapping{recurse} = $$rARGS{recurse};
    $mapping{match_type} = $$rARGS{match_type};
    $mapping{match_string} = $$rARGS{match_string};
    $mapping{brick_name} = $$rARGS{brick_name};

    if (!defined $$rARGS{position}) {
      $mapper->insert($#$rary + 1,\%mapping);  
    }
    else {
      $mapper->update($$rARGS{position}, \%mapping);  
    }

  }
  
</%perl>
</%method>

%#---------------------------------------------------------------------
%# render
%#---------------------------------------------------------------------
<%method render>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode) = @_;

  if (!defined $HTML::Bricks::session{username}) {
    $m->out('<b>access denied</b>');
    return;
  }

  use Apache::Util qw(escape_uri);
  use HTML::Bricks::Mappings;

  my $r = Apache->request;
  my $mapper = HTML::Bricks::Mappings->new();

  #
  # process any parameters
  #

  my $testoutput;

  my $teststr = (defined $$rARGS{teststr}) ? $$rARGS{teststr} : '/index.html';

  if (defined $$rARGS{test}) {
    my @matches = $mapper->get_matches($$rARGS{teststr});

    if ($#matches == -1) {
      $testoutput = "matched no mappings";
    }
    else {
      $testoutput = "matched:<br>\n";
      foreach (@matches) {
        $testoutput .= "$_<br>\n";  
      }
    }
  }

  #
  # get data
  #
  
  my $rary = $mapper->get_list();

</%perl>

<b>mappings</b>
<p>

<form method="post" action="<% $uri %>">
  <table border="0">    
    <tr>
      <td>
        <select name="<% $route_tag %>:op">
          <option value="">- op -
          <option value="new">new mapping
%         if ($#$rary != -1) {
            <option value="edit">edit
%           if ($#$rary > 0) {
              <option value="move">move
%           }          
            <option value="delete">delete
%         }
        </select>
      </td>
      <td>
        <select name="<% $route_tag %>:source">
          <option value="">- source -
%         for (my $i=0; $i <= $#$rary; $i++) {
            <option value="<% $i %>"><% $i+1 %>
%         }
        </select>
      </td>
      <td>
        <select name="<% $route_tag %>:dest">
          <option value="">- dest -
%         for (my $i=0; $i <= $#$rary; $i++) {
            <option value="<% $i %>"><% $i+1 %>
%         }
          <option value="<% $#$rary + 1 %>">bottom
        </select>
        <input type="submit" value="go">
      </td>
    </tr>
  </table>
</form> 

<table width="100%" border="1">
  <tr>
    <td>
      <table width="100%" border="0">
        <tr>
          <td>
          </td>
          <td>
            folder
          </td>
          <td>
            recurse
          </td>
          <td>
            type
          </td>
          <td>
            match
          </td>
          <td>
            assembly
          </td>
        </tr>
% foreach (my $i=0; $i <= $#$rary; $i++) {
%   my $rm = $$rary[$i];
        <tr>
          <td> 
            <a href="<% $uri %><% $route_tag %>:op=edit&<% $route_tag %>:source=<% $i %>"><% $i+1 %></a>.
          </td>
          <td>
            <% $$rm{folder} %>
          </td>
          <td>
            <% $$rm{recurse} %>
          </td>
          <td>
            <% $$rm{match_type} %>
          </td>
          <td>
            <% $$rm{match_string} %>
          </td>
          <td>
            <a href="/?g:bricks_edit_assy=<% escape_uri($$rm{brick_name}) %>"><% $$rm{brick_name} %></a>
          </td>
        </tr>    
% }
      </table>
    </td>
  </tr>
</table>

<form method="post" action="<% $uri %>">
  test uri:
  <input type="text" name="<% $route_tag %>:teststr" value="<% $teststr %>">
  <input type="submit" name="<% $route_tag %>:test" value="test">
</form>

<% $testoutput %>

</%method>

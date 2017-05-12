%#----------------------------------------------------------------------------
%# File: weblog
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# delete
%#----------------------------------------------------------------------------
<%method delete>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render_edit
%#----------------------------------------------------------------------------
<%method render_edit>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};

  my $name = $$rdata{name};
  my $sort_by = $$rdata{sort_by};
  my $sort_order = $$rdata{sort_order};
  my $description = $$rdata{description};

  my @sort_bys = ('mtime');

  my $sel_asc;
  my $sel_desc;
  if ($sort_order eq 'asc') {
    $sel_asc = 'selected';
  }
  else {
    $sel_desc = 'selected';
  }

</%perl>
<form method="post" action="<% $$ruri %>">
  <b>weblog properties</b>
  <p>
  <table border="0">
    <tr>
      <td align="right">
        name 
      </td>
      <td>
        <input type="text" name="<% $route_tag %>:name" value="<% $name %>" size="40">
      </td>
    </tr>
    <tr>
      <td align="right">
        sort&nbsp;by
      </tr>
      <td>
        <select name="<% $route_tag %>:sort_by">
          <option value="mtime" selected>last updated
        </select>
      </td>
    </tr>
    <tr>
      <td>
        sort&nbsp;order
      </td>
      <td>
        <select name="<% $route_tag %>:sort_order">
          <option value="asc" <% $sel_asc %>>ascending
          <option value="desc" <% $sel_desc %>>descending
        </select>
      </td>
    </tr>
    <tr>
      <td align="right">
        description
      </td>
      <td>
        <textarea name="<% $route_tag %>:description" rows="4" cols="40"><% $description %></textarea>
      </td>
    </tr>
    <tr>
      <td colspan=2 align="right">
        <input type="reset" value="reset">
        <input type="submit" name="<% $route_tag %>:weblog" value="update">
      </td>
    </tr>
</form>
</%method>
 
%#----------------------------------------------------------------------------
%# render_edit_weblog
%#----------------------------------------------------------------------------
<%method render_edit_weblog>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;
 
  my $r = Apache->request; 
  my $rdata = $$rbrick{data};
 
  my $entry_id = $$rARGS{entry_id};

  my ($title, $mtime, $description, $data);

  if (defined $entry_id) {
    my $filename = $HTML::Bricks::Config{bricks_root} . "/data/weblog/$$rdata{name}/$entry_id";
    my $fh = Apache::gensym();
    open($fh,"< $filename");

    my $string = join('',<$fh>);
    my $VAR1;
    eval($string);

    $title = $$VAR1{title};
    $mtime = $$VAR1{mtime};
    $description = $$VAR1{description};
    $data = $$VAR1{data};
  }
  else {
    $mtime = time; 
    
    my $filename = $HTML::Bricks::Config{bricks_root} . '/data/weblog/' . $$rdata{name};

    use Apache::File;
    my $fh = Apache::gensym();
    opendir($fh,$filename);
    my @logs = readdir($fh);
    close($fh);

    my @sorted_logs = sort { $b <=> $a } @logs;

    my $last = shift @sorted_logs;
   
    $entry_id = $last + 1;

  }

  my @t = localtime($mtime);
  my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

</%perl>
<b>weblog entry properties</b>
<p>
<form method="post" action="<% $$ruri %>">
% if (defined $entry_id) {
  <input type="hidden" name="<% $route_tag %>:entry_id" value="<% $entry_id %>">
% }
  <table border="0">
    <tr>
      <td align="right">
        title
      </tr>
      <td>
        <input type="text" name="<% $route_tag %>:title" value="<% $title %>" size="30">
      </td>
    </tr>
    <tr>
      <td align="right">
        date/time
      </td>
      <td>
        <select name="<% $route_tag %>:month">
%         for (my $i=0; $i < $#months; $i++) {
%           my $sel = 'selected' if $i == $t[4];
            <option <% $i %> <% $sel %>><% $months[$i] %>
%         }
        </select>
        <select name="<% $route_tag %>:day">
%         for (my $i=0; $i < 32; $i++) {
%           my $sel = 'selected' if $i == $t[3];
            <option <% $i %> <% $sel %>><% $i %>
%         }
        </select>
        <select name="<% $route_tag %>:year">
%         for (my $i=90; $i < 105; $i++) {
%           my $sel = 'selected' if $i == $t[5];
            <option <% $i %> <% $sel %>><% $i+1900 %>
%         }
        </select>
        &nbsp;&nbsp;
        <select name="<% $route_tag %>:hour">
%         for (my $i=0; $i < 24; $i++) {
%           my $sel = 'selected' if $i == $t[2];
            <option <% $i %> <% $sel %>><% ($i < 10) ? '0' : '' %><% $i %>
%         }
        </select>:<select name="<% $route_tag %>:minute">
%         for (my $i=0; $i < 60; $i++) {
%           my $sel = 'selected' if $i == $t[1];
            <option <% $i %> <% $sel %>><% ($i < 10) ? '0' : '' %><% $i %>
%         }
        </select>
      </td>
    </tr>
    <tr>
      <td align="right">
        description
      </td>
      <td>
        <input type="text" name="<% $route_tag %>:description" value="<% $description %>" size="50">
      </td>
    </tr>
  </table> 
  <textarea name="<% $route_tag %>:data" rows="30" cols="60"><% $data %></textarea>
  <br>
  <input type="submit" name="<% $route_tag %>:submit" value="update">
  <input type="reset" value="reset">
</form>
</%method>

%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};
  my $r = Apache->request;

  if ($mode eq 'edit') {
    if ($$rARGS{fn} eq 'edit') {
      $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };
    }

    if ($$rARGS{weblog} eq 'update') {

      $$rdata{name} = $$rARGS{name}; 
      $$rdata{sort_by} = $$rARGS{sort_by};
      $$rdata{sort_order} = $$rARGS{sort_order};
      $$rdata{description} = $$rARGS{description};

      $rparent_brick->set_modified();
    }
  }

  if (defined $$rARGS{new_entry}) {
    $$ruri .= "$route_tag:entry=$$rARGS{new_entry}&";
  }
  elsif (defined $$rARGS{weblog_title}) {
    $$ruri .= $route_tag . ':weblog_title=' . escape_uri($$rARGS{weblog_title}) .'&';
  }
  elsif (defined $$rARGS{entry}) {
    $$ruri .= "$route_tag:entry=$$rARGS{entry}&";
  }

  if (defined $$rARGS{edit_weblog}) {
    $$rredirect = sub { $rbrick->render_edit_weblog($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };
  }
  
  if (defined $$rARGS{delete_weblog}) {
    my $entry_id = $$rARGS{entry_id};
    my $filename = $HTML::Bricks::Config{bricks_root} . "/data/weblog/$$rdata{name}/$entry_id";
    unlink $filename;
  }

  if ($$rARGS{submit} eq 'update') {
    my $filename = $HTML::Bricks::Config{bricks_root} . '/data/weblog';

    if (! -e $filename) {
      mkdir($filename);
      if (! -e $filename) {
        print STDERR "weblog: ERROR couldn't create $filename\n";
      }
    }

    $filename .= '/' . $$rdata{name};
    if (! -e $filename) {
      mkdir $filename;

      if (! -e $filename) {
        print STDERR "weblog: ERROR couldn't create $filename\n";
      }
    }

    use Time::Local;

    my %entry;

    my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
    my $month;

    for (my $i=0; $i < $#months; $i++) {
      if ($months[$i] eq $$rARGS{month}) {
        $month = $i;
      }
    }

    my $entry_id = $$rARGS{entry_id};
    $entry{title} = $$rARGS{title};
    $entry{mtime} = timelocal(0,$$rARGS{minute},$$rARGS{hour},$$rARGS{day},$month,$$rARGS{year});
    $entry{description} = $$rARGS{description};
    $entry{data} = $$rARGS{data};

    $filename .= '/' . $entry_id;

    use Apache::File;
    my $fh = Apache::gensym();
    open($fh,"> $filename");
    print $fh Dumper(\%entry);
    close($fh);
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

  return if !defined $$rdata{name};

  my $r = Apache->request;
  my $dirname = $HTML::Bricks::Config{bricks_root} . '/data/weblog' . '/' . $$rdata{name};
  use Apache::File;
  my $fh = Apache::gensym();
  opendir($fh,$dirname);
  my @logs = readdir($fh);
  close($fh);

  my @titles;

  foreach (@logs) {

    my $filename = $dirname . '/' . $_;

    next if -d $filename;

    my $fh = Apache::gensym();
    open($fh,"< $filename");

    my $string = join('',<$fh>);
    my $VAR1;
    eval($string);

    my $rlog = $VAR1;

    push @titles, [ $filename, $_, $$rlog{mtime}, $$rlog{title} ];

    close($fh);
  }

  my @sorted_titles = sort { $$b[2] <=> $$a[2] } @titles;
  @titles = @sorted_titles;

  my $rtitle;

  if (defined $$rARGS{new_entry}) {
    $$rtitle[0] = $HTML::Bricks::Config{bricks_root} . "/data/weblog/$$rdata{name}/$$rARGS{new_entry}";
    $$rARGS{entry} = $$rARGS{new_entry};
  }
  elsif (defined $$rARGS{weblog_title}) {
    foreach (@titles) {
      if ($$_[3] eq $$rARGS{weblog_title}) {
        $rtitle = $_;
        $$rARGS{entry} = $$_[1];
        last;
      }
    }
  }
  elsif (defined $$rARGS{entry}) {
    $$rtitle[0] = $HTML::Bricks::Config{bricks_root} . "/data/weblog/$$rdata{name}/$$rARGS{entry}";

    if (! -e $$rtitle[0]) {
      undef $rtitle;
    }
  }

  if (!defined $rtitle) {
    $rtitle = $titles[0];
  }

  my %weblog;
  if (defined $rtitle) {
    my $fh = Apache::gensym();
    open($fh,"< $$rtitle[0]");

    my $string = join('',<$fh>);
    my $VAR1;
    eval($string);

    %weblog  = %$VAR1;
   
    my $i = rindex($$rtitle[0],'/') + 1;
    $weblog{id} = substr($$rtitle[0], $i, length($$rtitle[0]) - $i);
  }

  my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

</%perl>
<table cellspacing="0" cellpadding="5" width="600" border="0" class="weblog">
%  if (defined $HTML::Bricks::session{username}) {
  <tr>
    <td colspan=2 align="right">
      <a href="<% $uri %><% $route_tag %>:edit_weblog=1">add</a>
    </td>
  </tr>
%  }
% if ($#titles != -1) {
  <tr>
    <td colspan="2" align="center">
      <form method="post" action="<% $uri %>">
        <select onchange="submit()" name="<% $route_tag %>:new_entry">
%         for (my $i=0; $i <= $#titles; $i++) {
%           my $sel = (${$titles[$i]}[1] == $$rARGS{entry}) ? ' selected' : '';

            <option value="<% ${$titles[$i]}[1] %>"<% $sel %>><% ${$titles[$i]}[3] %>
%         }
        </select>
        <noscript>
          <input type="submit" value="go">
        </noscript>
      </form>
      <p>
    </td>
  </tr>  
% }
% if (defined $weblog{mtime}) {
  <tr height="700">
    <td width="1" align="right" valign="top" class="weblog_date">
%     my @lt = localtime($weblog{mtime});
%     my $time = $lt[3] . '&nbsp;' . $months[$lt[4]] . '&nbsp;' . (1900 + $lt[5]);
      <% $time %>
    </td>
    <td width="100%" valign="top">
      <% $weblog{data} %>
%  if (defined $HTML::Bricks::session{username}) {
       <br>
       <a href="<% $uri %><% $route_tag %>:edit_weblog=1&<% $route_tag %>:entry_id=<% $weblog{id} %>">edit</a>
       <a href="<% $uri %><% $route_tag %>:delete_weblog=1&<% $route_tag %>:entry_id=<% $weblog{id} %>">delete</a>
%     }
    </td>
  </tr>
% }
</table>
</%method>

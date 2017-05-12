%#----------------------------------------------------------------------------
%# File: photoalbum
%#
%# I dedicate this brick to the Sasha Xpander EP (music) which kept me working
%# when my code wasn't.
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my ($rbrick) = @_;
  
  my ($name, $folder, $sort_by, $sort_order, $description);

  my $rdata = $$rbrick{data};

  $$rdata{filename} = '';
  $$rdata{return} = undef;

  $$rdata{rfileselect} = HTML::Bricks::fetch('fileselect');
  $$rdata{rfileselect}->new('open', $HTML::Bricks::Config{document_root}, \$$rdata{filename}, \$$rdata{return});

  $$rdata{name} = $name;
  $$rdata{folder} = $folder;
  $$rdata{sort_by} = $sort_by;
  $$rdata{sort_order} = $sort_order;
  $$rdata{description} = $description;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# delete
%#----------------------------------------------------------------------------
<%method delete>
<%perl>
  my ($rbrick) = @_;
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# get_info
%#----------------------------------------------------------------------------
<%method get_info>
<%perl>
  my ($rbrick) = @_;

  $rbrick->check_update();

  my $rdata = $$rbrick{data};
 
  return %$rdata;
 
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# set_info
%#----------------------------------------------------------------------------
<%method set_info>
<%perl>
  my ($rbrick, $rinfo) = @_;

  my $rdata = $$rbrick{data};

  $$rdata{name} = $$rinfo{name};
  $$rdata{folder} = $$rinfo{folder};
  $$rdata{sort_by} = $$rinfo{sort_by};
  $$rdata{sort_order} = $$rinfo{sort_order};
  $$rdata{description} = $$rinfo{description}; 
 
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# freeze
%#----------------------------------------------------------------------------
<%method freeze>
<%perl>
  my ($rbrick) = @_;

  my %node;
  $node{name} = $$rbrick{name};
  my $rnode_data = $node{data} = {};

  my $rdata = $$rbrick{data};
  %$rnode_data = %$rdata;

  $$rnode_data{frozen_fileselect} = $$rdata{rfileselect}->freeze();
  delete $$rnode_data{rfileselect};

  return \%node;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# thaw
%#----------------------------------------------------------------------------
<%method thaw>
<%perl>
  my ($rbrick, $rnode) = @_;

  $rbrick->new();

  my $rnode_data = $$rnode{data};
  my $rdata = $$rbrick{data};

  %$rdata = %$rnode_data;

  $$rdata{rfileselect} = HTML::Bricks::fetch('fileselect');
  $$rdata{rfileselect}->thaw($$rnode_data{frozen_fileselect}, $HTML::Bricks::Config{document_root}, \$$rdata{filename}, \$$rdata{return});

  return $rbrick;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render_edit
%#----------------------------------------------------------------------------
<%method render_edit>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;


  my $rdata = $$rbrick{data};

  if ($$rdata{mode} eq 'select') {
    $$rdata{rfileselect}->render($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,'',$$ruri,$mode);

    return;
  }

  my $name = $$rdata{name};
  my $folder = $$rdata{folder};
  my $sort_by = $$rdata{sort_by};
  my $sort_order = $$rdata{sort_order};
  my $description = $$rdata{description};

  my $date_sel;
  my $name_sel;
  my $ascending_sel;
  my $descending_sel;

  ($sort_by eq 'name') ? $name_sel = "selected" : $date_sel = "selected";
  ($sort_order eq 'asc') ? $ascending_sel = "checked" : $descending_sel = "checked";

</%perl>

<form method="post" action="<% $$ruri %>">
  <input type="hidden" name="<% $route_tag %>:fn" value="process_edit">

  <b>photo album properties</b>
  <p>
  name <input type="text" name="<% $route_tag %>:name" value="<% $name %>" size="20">
  <br>
  server folder <input type="text" name="<% $route_tag %>:folder" value="<% $folder %>" size="70">
  <input type="submit" name="<% $route_tag %>:select" value="select">
% if (defined $$rdata{input_error}) {
  <br>
  <b>Error: the server folder name is not valid</b>
  <br>
% }
  <br>
  sort pictures by
  <select name="<% $route_tag %>:sort_by">
    <option value="mtime" <% $date_sel %>>date
    <option value="name" <% $name_sel %>>name
  </select>
  <input type="radio" name="<% $route_tag %>:sort_order" value="asc" <% $ascending_sel %>>ascending
  <input type="radio" name="<% $route_tag %>:sort_order" value="desc" <% $descending_sel %>>descending
  <br>
  <textarea name="<% $route_tag %>:description" cols="80" rows="15"><% $description %></textarea>
  <br>
  <input type="submit" name="<% $route_tag %>:update" value="update">
  <input type="reset" value="reset">
</form>
</%method>
 
%#----------------------------------------------------------------------------
%# process_edit
%#----------------------------------------------------------------------------
<%method process_edit>
<%perl>
  my ($rbrick,$rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};

  if ($$rdata{mode} eq 'select') {

    $$rdata{rfileselect}->process($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect);

    if (defined $$rdata{return}) {

      delete $$rdata{mode}; 

      if ($$rdata{return} eq 'open') {
        $$rdata{folder} = $$rdata{filename};
      }

      $$rdata{return} = undef;
    }

    $$rredirect = sub { $rbrick->render_edit($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
  }

  if ($$rARGS{select} eq 'select') {
    $$rdata{mode} = 'select';
    $$rredirect = sub { $rbrick->render_edit($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
    return;
  }

  if ($$rARGS{update} eq 'update') {
    $$rdata{name} = $$rARGS{name};
    $$rdata{folder} = $$rARGS{folder};
    $$rdata{sort_by} = $$rARGS{sort_by};
    $$rdata{sort_order} = $$rARGS{sort_order};
    $$rdata{description} = $$rARGS{description};
  }

  #
  # Error check
  #

  delete $$rdata{input_error};

  #
  # Check to see if the server folder is valid
  #

  my $r = Apache->request;
  my $f = $r->document_root . $$rdata{folder}; 
  if (! -d $f) {
    $$rdata{input_error} |= 1;
  }

  #
  # redirect if error
  #

  if (defined $$rdata{input_error}) {
    $$rredirect = sub { $rbrick->render_edit($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
    return;
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# check_update
%#----------------------------------------------------------------------------
<%method check_update>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};
  my $r = Apache->request;

  use Apache::File;
  my $fh = Apache::gensym();

  my $filename = $r->document_root . "/$$rdata{folder}";
  opendir($fh,$filename);
  my @files = readdir($fh);
  close($fh);

  my @photos;
  my $mtime = 0;
  my $nphotos = 0;

  foreach (@files) {
    if (($_ =~ /(.*)\.[jJ][pP][eE]?[gG]/) ||
        ($_ =~ /(.*)\.[tT][iT][fF][fF]?/) ||
        ($_ =~ /(.*)\.[gG][iI][fF]/)) {

      my $filename = $r->document_root . "/$$rdata{folder}/$_";
      next if -d $filename;
      my @statdata = stat($filename);

      if ($statdata[9] > $mtime) { 
        $mtime = $statdata[9];
      }
     
      $nphotos++;
    }
  }

  $$rdata{nphotos} = $nphotos;
  $$rdata{mtime} = $mtime;

</%perl>
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
      $$rredirect = sub { $rbrick->render_edit($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
    }
    if (($$rARGS{fn} eq 'process_edit') || ($$rdata{mode} eq 'select')) {
      $rbrick->process_edit($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect);
    }
  }

  my $zoom = (defined $$rARGS{new_zoom}) ? $$rARGS{new_zoom} : $$rARGS{zoom};
  my $n = (defined $$rARGS{new_n}) ? $$rARGS{new_n} : $$rARGS{n};

  if (defined $zoom) { 
    $$rARGS{zoom} = $zoom;
    $$ruri .= "$route_tag:zoom=$zoom&";
  }
 
  if (defined $n) {
    $$rARGS{n} = $n;
    $$ruri .= "$route_tag:n=$n&";   
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render
%#----------------------------------------------------------------------------
<%method render>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode) = @_;

  use Apache::Util qw(escape_uri);

  my $r = Apache->request;
  my $rdata = $$rbrick{data};
  if (!defined $$rdata{folder}) {
    return;
  }

  my $name = $$rdata{name};
  my $folder = $$rdata{folder};
  my $sort_by = $$rdata{sort_by};
  my $sort_order = $$rdata{sort_order};
  my $nphotos = $$rdata{nphotos};
  my $description = $$rdata{description};

  use Apache::File;
  my $fh = Apache::gensym();

  my $filename = $r->document_root . "/$folder";
  opendir($fh,$filename);
  my @files = readdir($fh);
  close($fh);

  my @photos;
  foreach (@files) {
    if (($_ =~ /(.*)\.[jJ][pP][eE]?[gG]/) ||
        ($_ =~ /(.*)\.[tT][iT][fF][fF]?/) ||
        ($_ =~ /(.*)\.[gG][iI][fF]/)) {

      my $filename = $r->document_root . "/$folder/$_";
      next if -d $filename;
      my @statdata = stat($filename);

      push @photos, [ $filename, "$folder/$_", $_, $statdata[9], $1 ];
    }
  }

  return if $#photos == -1;

  #
  # sort the photos
  #

  my @sorted_photos;

  if ($$rdata{sort_by} eq 'mtime') {

    if ($$rdata{sort_order} eq 'asc') {
      @sorted_photos = sort { $$a[3] <=> $$b[3] } @photos;
    }
    else {
      @sorted_photos = sort { $$b[3] <=> $$a[3] } @photos;
    }

  }
  elsif ($$rdata{sort_by} eq 'name') {

    if ($$rdata{sort_order} eq 'asc') {
      @sorted_photos = sort { $$a[2] cmp $$b[2] } @photos;
    }
    else {
      @sorted_photos = sort { $$b[2] cmp $$a[2] } @photos;
    }
  }
  else {
    @sorted_photos = @photos;
  }

  @photos = @sorted_photos;

  #
  # either draw an index page or a close-up page
  #

  my @zooms = ( [90, -1, 6], [300, 6, 2], [700, 1, -1], ['fullsize', 1, -1] );
  my $zoom = (defined $$rARGS{zoom}) ? $$rARGS{zoom} : 0;
  
  if ($zoom > $#zooms) {
    $zoom = $#zooms;
  }

  my $rzoom = $zooms[$zoom];
  my $size = $$rzoom[0];
  my $nperpage = ($$rzoom[1] > 0) ? $$rzoom[1] : ($#photos + 1);
  my $cols = ($$rzoom[2] > 0) ? $$rzoom[2] : int(sqrt($nperpage) + 0.999); 

  my $photo_num = ($$rARGS{n}) ? $$rARGS{n} : 0;
  my $start_num = $photo_num - ($photo_num % $nperpage);

  my $end_num = $start_num + ($nperpage -1);
  if ($end_num > $#photos) {
    $end_num = $#photos;
  }

  #
  # photo selecton bar
  #

  my $photo_select_bar;
  if (($#photos > 1)  && ($nperpage == 1)) {
    my $href = $uri;
    $photo_select_bar = "<form method=\"post\" action=\"$href\">\n"; 
    $photo_select_bar .= "  <input type=\"hidden\" name=\"$route_tag:new_zoom\" value=\"2\">\n";
    $photo_select_bar .= "  <select onchange=\"submit()\" name=\"$route_tag:new_n\">\n";

    my $i=0;
    foreach (@photos) {
      my $sel;

      if ($i == $photo_num) { 
        $sel = 'selected';
      }
     
      $photo_select_bar .= "    <option value=\"$i\" $sel>$$_[4]\n";
      $i++;
    }

    $photo_select_bar .= "  </select>\n";
    $photo_select_bar .= "  <noscript><input type=\"submit\" value=\"go\"></noscript>\n";
    $photo_select_bar .= "</form>\n";
  }


  #
  # navigation bar
  #

  my $nav_bar;
  
  if ($nperpage < $#photos) {
    my $href = "$uri$route_tag:new_zoom=0";
    $nav_bar = "<a href=\"$href\">all</a>";
    $nav_bar .= '&nbsp;&nbsp;';
 
    $href = $uri;
    if ($zoom > 1) {
      $nav_bar .= "<a href=\"$href$route_tag:new_zoom=" . ($zoom-1) . "&$route_tag:new_n=$start_num\">zoom out</a> ";
      $nav_bar .= '&nbsp;&nbsp;';
    }

    $href .= "$route_tag:new_n=";

    if ($nperpage > 1) {

      if ($start_num == 0) {
        $nav_bar .= "prev";
      }
      else {
        $nav_bar .= "<a href=\"$href" . ($start_num - $nperpage) . "\">prev</a>";
      }
      $nav_bar .= '&nbsp;&nbsp;';

      my $this_page = int( $start_num / $nperpage ) + 1;
      for (my $i=0; $i <= (int($#photos / $nperpage)); $i++) {
        my $p = $i+1;
        if ($p == $this_page) {
          $nav_bar .= "$p ";
        }
        else {
          $nav_bar .= "<a href=\"$href" . ($i * $nperpage) . "\">$p</a> ";
        }
      }
      $nav_bar .= '&nbsp;&nbsp;';

      if ($end_num == $#photos) {
        $nav_bar .= "next";
      }
      else {
        $nav_bar .= "<a href=\"$href". ($start_num + $nperpage) . "\">next</a>";
      }
    }
  } 

</%perl>
  <table width="<% $size * $cols %>" cellspacing="0" cellpadding="0" border="0" class="photoalbum">
    <tr>
      <td align="center" colspan="<% $cols %>" class="photoalbum">
        <% $name %>
      </td>
    </tr>
    <tr>
      <td colspan="<% $cols %>" class="photoalbum">
        <% $nav_bar %>
        <center><% $photo_select_bar %></center>
      </td>
    </tr>
    <tr>
      <td colspan="<% $cols %>" class="photoalbum">
        <% $description %>
      </td>
    </tr>
<%perl>

  my $c=0;
  for (my $i=$start_num; $i <= $end_num; $i++) {
    my ($rphoto, $href, $cwidth, $cheight, $pheight, $filename, $title, $description);

    $rphoto = $photos[$i];

    if ($zoom < $#zooms) {
      $href = "$uri$route_tag:new_zoom=" . ($zoom + 1) . "&$route_tag:new_n=$i";
    }

    $filename = escape_uri($$rphoto[1]);

    if ($size ne 'fullsize') {
      $cwidth = $size + 9;
      $cheight = $size + 40;
      $pheight = $size + 9;
      $filename .= "?Resize:geometry=" . $size . "x" . $size;
    }
    else {
      $cwidth = 0;
      $cheight = 0;
      $pheight = 0;
    }
    
    if (($#photos != 1) && ($nperpage != 1)) {
      $title = $$rphoto[4];
    }

    if ($nperpage < $#photos) {
      if ($$rphoto[5]) { 
        $description = "<p>$$rphoto[5]";
      }
    } 

    if ($c % $cols == 0) {
      $m->out("<tr>\n");
    }

</%perl>
  <td width="<% $cwidth %>" height="<% $cheight %>" valign="top" align="center" class="photoalbum"> 
    <table width="<% $cwidth %>" border="0" cellspacing="0" cellpadding="0">
      <tr width="<% $cwidth %>" height="<% $cheight %>">
        <td align="center" width="<% $size %>" height="<% $pheight %>" class="photoalbum">
% if (defined $href) {
          <a href="<% $href %>"><img border=0 src="<% $filename %>"></a>
% } else {
          <img border=0 src="<% $filename %>">
% }
        </td>
      </tr>
      <tr width="<% $size %>">
        <td width="<% $size %>" height="66" align="left" valign="top" class="photoalbum">
% if (defined $href) {
          <a href="<% $href %>"><% $title %></a>
          <a href="<% $href %>"><% $description %></a> 
% } else {
          <% $title %>
          <% $description %>
% }
        </td>
      </tr>
    </table> 
  </td>
<%perl>
    
    $c++;
    if ($c % $cols == 0) {
      $m->out("</tr>\n");
    }
      
  }
</%perl>
    </tr>  
    <tr>
      <td colspan="<% $cols %>" class="photoalbum">
        <% $nav_bar %>
      </td>
    </tr>
  </table>
</%method>

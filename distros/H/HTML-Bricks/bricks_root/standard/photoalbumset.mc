%#----------------------------------------------------------------------------
%# File: photoalbumset
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};

  $$rdata{sort_by} = 'mtime';
  $$rdata{sort_order} = 'asc';

  $$rdata{filename} = '';
  $$rdata{return} = undef;

  $$rdata{rfileselect} = HTML::Bricks::fetch('fileselect');
  $$rdata{rfileselect}->new('open', $HTML::Bricks::Config{document_root}, \$$rdata{filename}, \$$rdata{return});

  $$rdata{ralbums} = {};
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# delete
%#----------------------------------------------------------------------------
<%method delete>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};
  my $ralbum_list = $$rdata{ralbum_list};

  my $ralbums = $$rdata{ralbums};
  foreach (keys %$ralbums) {
    $$ralbums{$_}->delete();
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# freeze
%#----------------------------------------------------------------------------
<%method freeze>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};

  my %node;
  $node{name} = $$rbrick{name};
  my $rnode_data = $node{data} = {};

  $$rnode_data{filename} = $$rdata{filename};
  $$rnode_data{tied_folder} = $$rdata{tied_folder};

  $$rnode_data{name} = $$rdata{name};
  $$rnode_data{sort_by} = $$rdata{sort_by};
  $$rnode_data{sort_order} = $$rdata{sort_order};

  $$rnode_data{mode} = $$rdata{mode};

  my $rnode_albums = $$rnode_data{ralbums} = {};

  my $ralbums = $$rdata{ralbums};

  foreach (keys %$ralbums) {
    $$rnode_albums{$_} = $$ralbums{$_}->freeze();
  }

  $$rnode_data{frozen_fileselect} = $$rdata{rfileselect}->freeze();

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
  $$rdata{filename} = $$rnode_data{filename};
  $$rdata{tied_folder} = $$rnode_data{tied_folder};

  $$rdata{name} = $$rnode_data{name};
  $$rdata{sort_by} = $$rnode_data{sort_by};
  $$rdata{sort_order} = $$rnode_data{sort_order};
  $$rdata{mode} = $$rnode_data{mode};

  my $ralbums = $$rdata{ralbums} = {};
  my $rnode_albums = $$rnode_data{ralbums};

  foreach (keys %$rnode_albums) {
    $$ralbums{$_} = HTML::Bricks::fetch('photoalbum');
    $$ralbums{$_}->thaw($$rnode_albums{$_});
  }

  $$rdata{return} = undef;

  $$rdata{rfileselect} = HTML::Bricks::fetch('fileselect');
  $$rdata{rfileselect}->thaw($$rnode_data{frozen_fileselect},$HTML::Bricks::Config{document_root},\$$rdata{filename},\$$rdata{return});

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
    $$rdata{rfileselect}->render($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, '', $$ruri, $mode);

    return;
  }

  my ($name, $sort_by, $sort_order, $tied_folder);

  $name = $$rdata{name};
  $sort_by = $$rdata{sort_by};
  $sort_order = $$rdata{sort_order};
  $tied_folder = $$rdata{tied_folder};

  my $mtime_sel = ($sort_by eq 'mtime') ? 'selected' : '';
  my $nphotos_sel = ($sort_by eq 'nphotos') ? 'selected' : '';
  my $name_sel = ($sort_by eq 'name') ? 'selected' : '';
  my $asc_sel = ($sort_order eq 'asc') ? 'checked' : '';
  my $desc_sel = ($sort_order eq 'desc') ? 'checked' : '';

</%perl>

<form method="post" action="<% $$ruri %>">
  <input type="hidden" name="<% $route_tag %>:fn" value="process_edit">

  <b>photo album set properties</b>
  <p>

  name <input type="text" name="<% $route_tag %>:name" value="<% $name %>" length="20">
  <br>
  sort photo albums by
  <select name="<% $route_tag %>:sort_by">
    <option value="mtime" <% $mtime_sel %>>update time
    <option value="nphotos" <% $nphotos_sel %>>number of photos
    <option value="name" <% $name_sel %>>name
  </select>

  <input type="radio" name="<% $route_tag %>:sort_order" value="asc" <% $asc_sel %>>ascending
  <input type="radio" name="<% $route_tag %>:sort_order" value="desc" <% $desc_sel %>>descending

  <p>
  A photo album set is tied to a folder on the web-server such that
  any folders within that folder become photo albums in this photo 
  album set.
  <p>
  folder name <input type=text name="<% $route_tag %>:tied_folder" value="<% $tied_folder %>" size="70">
  <input type="submit" name="<% $route_tag %>:select" value="select">
% if (defined $$rdata{input_error}) {
  <br>
  <b>Error: the server folder name is not valid</b>
  <br>
% }
  <p>
  <input type="submit" name="<% $route_tag %>:update" value="update">
  <input type="reset" value="reset">
  
</form>

</%method>
 
%#----------------------------------------------------------------------------
%# process_edit
%#----------------------------------------------------------------------------
<%method process_edit>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;
  my $rdata = $$rbrick{data};

  if ($$rdata{mode} eq 'select') {

    $$rdata{rfileselect}->process($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect);

    if (defined $$rdata{return}) {
      delete $$rdata{mode}; 

      if ($$rdata{return} eq 'open') {
        $$rdata{tied_folder} = $$rdata{filename};
        $$rdata{mtime} = -1;
      }

      $$rdata{return} = undef;
    }

    $$rredirect = sub { $rbrick->render_edit($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect); };
  }

  if ($$rARGS{select} eq 'select') {
    $$rdata{mode} = 'select';
    $$rredirect = sub { $rbrick->render_edit($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect); };

    return;
  }

  if ($$rARGS{update} eq 'update') {

    if ($$rdata{tied_folder} ne $$rARGS{tied_folder}) {
      $$rdata{mtime} = -1;
    }

    $$rdata{name} = $$rARGS{name};
    $$rdata{sort_by} = $$rARGS{sort_by};
    $$rdata{sort_order} = $$rARGS{sort_order};
    $$rdata{tied_folder} = $$rARGS{tied_folder};  
  }

  #
  # Error check
  #

  delete $$rdata{input_error};

  #
  # Check to see if the server folder is valid
  #

  my $r = Apache->request;
  my $f = $r->document_root . $$rdata{tied_folder}; 
  if (! -d $f) {
    $$rdata{input_error} |= 1;
  }

  #
  # redirect if error
  #

  if (defined $$rdata{input_error}) {
    $$rredirect = sub { $rbrick->render_edit($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect); };
    return;
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# process($rARGS, $rbrick)
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;
  use Apache::Util qw(escape_uri);
  my $rdata = $$rbrick{data};

  if ($mode eq 'edit') {
    if (($$rARGS{fn} eq 'edit') || ($$rdata{mode} eq 'select')) {
      $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, $rARGS,
                          $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect); };
    }

    if (($$rARGS{fn} eq 'process_edit') || ($$rdata{mode} eq 'select')) {
      $rbrick->process_edit($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS,
                            $route_tag, $ruri, $mode, $rredirect);
      $rparent_brick->set_modified(); 
    }
  }

  my $name = $$rdata{name};
  my $sort_by = $$rdata{sort_by};
  my $sort_order = $$rdata{sort_order};
  my $tied_folder = $$rdata{tied_folder};
  my $ralbums = $$rdata{ralbums};

  #
  # see if the tied folder has been updated
  #

  my $mtime = $$rdata{mtime};
  my $r = Apache->request;
  my $dir = $r->document_root . "/" . $tied_folder;

  use Apache::File;
  my $fh = Apache::gensym();

  opendir($fh,$dir);
  my @files = readdir($fh);
  close($fh);

  my @dirs;
  foreach (@files) {

    my $filename = $dir . '/' . $_;

    if ((-d $filename) && ($_ ne '.') && ($_ ne '..')) {
      push @dirs, $_;
    }

  }

  my %ehash;
  if (defined $ralbums) {
    %ehash = %$ralbums;
  }

  my @adds;

  foreach (@dirs) {
    my $filename=  $dir . '/' . $_;

    if (!exists $ehash{$_}) {
      push @adds, $_;
    }
    else {
      delete $ehash{$_};
    }
  }

  #
  # delete any photoalbums that no longer exist
  #

  foreach (keys %ehash) {

    my $rphotoalbum = $ehash{$_};
    $rphotoalbum->delete();
    delete $$ralbums{$_};
    $rparent_brick->set_modified(); 
  }

  # 
  # add new phtoalbums
  #

  foreach (@adds) {
    my $folder = $tied_folder . '/' . $_;

    my $rbrick = HTML::Bricks::fetch('photoalbum');
    $rbrick->new();
    $rbrick->set_info({ name => $_, folder => $folder });
    $$ralbums{$_} = $rbrick;
    $rparent_brick->set_modified(); 
  }

  if (defined $$rARGS{new_album}) {
    delete $$rARGS{zoom};
    delete $$rARGS{n};
    delete $$rARGS{album};

    return if $$rARGS{new_album} eq '_list';

    $$rARGS{album} = my $album = $$rARGS{new_album};
    $$ruri .= "$route_tag:album=" . escape_uri($$rARGS{album}) . "&";
  }
  elsif (defined $$rARGS{album}) {
    $$ruri .= "$route_tag:album=" . escape_uri($$rARGS{album}) . "&";
 
 
    my $ralbums =  $$rdata{ralbums};
    my $rbrick = $$ralbums{$$rARGS{album}};

    return if !defined $rbrick;
    $rbrick->process($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect);
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render($rARGS, $rbrick)
%#----------------------------------------------------------------------------
<%method render>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode) = @_;

  use Apache::Util qw(escape_uri);

  my $rdata = $$rbrick{data};

  if (!defined $$rdata{tied_folder}) {
    return;
  }

  my $name = $$rdata{name};
  my $sort_by = $$rdata{sort_by};
  my $sort_order = $$rdata{sort_order};
  my $tied_folder = $$rdata{tied_folder};
  my $ralbums = $$rdata{ralbums};

  #
  # now traverse all the albums and get their mtimes and nphotos
  #

  my @photo_albums;

  foreach (keys %$ralbums) {

    my $rbrick = $$ralbums{$_};

    my %info = $rbrick->get_info();
    push @photo_albums, [ $info{folder}, $info{nphotos}, $info{mtime}, $_ ];
    
    $info{sort_by} = $sort_by;
    $info{sort_order} = $sort_order;
    $rbrick->set_info(\%info);
  }

  #
  # now sort the photo albums
  #
 
  my @sorted_photo_albums;
  if ($sort_by eq 'name') {
    if ($sort_order eq 'asc') {
      @sorted_photo_albums = sort { $$a[0] cmp $$b[0] } @photo_albums;
    }
    else {
      @sorted_photo_albums = sort { $$b[0] cmp $$a[0] } @photo_albums;
    }
  }
  elsif ($sort_by eq 'nphotos') {
    if ($sort_order eq 'asc') {
      @sorted_photo_albums = sort { $$a[1] <=> $$b[1] } @photo_albums;
    }
    else {
      @sorted_photo_albums = sort { $$b[1] <=> $$a[1] } @photo_albums;
    }
  }
  elsif ($sort_by eq 'mtime') {
    if ($sort_order eq 'asc') {
      @sorted_photo_albums = sort { $$a[2] <=> $$b[2] } @photo_albums;
    }
    else {
      @sorted_photo_albums = sort { $$b[2] <=> $$a[2] } @photo_albums;
    }
  }

  my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

  #
  # render either the PhotoAlbumSet list or the PhotoAlbum select bar and PhotoAlbum
  #

  my $album = $$rARGS{album};
  if (defined $album) {

</%perl>

  <table cellspacing="0" cellpadding="3" border="0" width="100%" class="photoablum">
    <tr>
      <td>
        <table width="100%" cellspacing="0" cellpadding="3" border="0" class="photoalbum">
          <tr>
            <td align="right" class="photoalbum">
              <form method="post" action="<% $uri %>">
                <select onchange="submit()" name="<% $route_tag %>:new_album">
                  <option value="_list">- full list -
%                 foreach (@sorted_photo_albums) {
%                   my $sel = ($$_[3] eq $album) ? 'selected' : ''; 
%                   my $name = $$_[3];
%                   if ($name =~ /\w\w\s-\s(.*)/) { $name = $1; }  # TODO: remove HACK for Peter's website
                      <option value="<% $$_[3] %>" <% $sel %>><% $name %>
%                  }
                </select>
                <noscript><input type="submit" value="go"></noscript>
              </form>
            </td>
          </tr>
          <tr>
            <td>
              &nbsp;
              <p>
            <td>
          </tr>
          <tr>
            <td align="center">
<%perl>

    my $rbrick = $$ralbums{$album};
    if (defined $rbrick) {
      $rbrick->render($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode);
    }
    else {
      $m->out("Sorry, the photo album named '$album' could not be found on the server\n");
    }

    $m->out("            </td>\n");
    $m->out("          </tr>\n");
    $m->out("        </table>\n");
    $m->out("      </td>\n");
    $m->out("    </tr>\n");
    $m->out("  </table>\n");

    return;
  }
  else {

</%perl>
    <table cellspacing=0 cellpadding=3 border=0 width="100%" class="weblog">
    <tr>
      <td align="center">
        date 
      </td>
      <td align="center">
        album
      </td>
      <td align="center">
        no. 
      </td>
% foreach (@sorted_photo_albums) {
%   my $href = $uri . "$route_tag:new_album=" . escape_uri($$_[3]);
%   my $name = $$_[3];
%   if ($name =~ /\w\w\s-\s(.*)/) { $name = $1; }  # TODO: remove HACK for Peter's website
      <tr>
        <td align="right">
%         my @lt = localtime($$_[2]);
%         my $time = $lt[3] . '&nbsp;' . $months[$lt[4]] . '&nbsp;' . (1900 + $lt[5]);
          <% $time %>&nbsp;
        </td>
        <td>
          <a href="<% $href %>"><% $name %></a>
        </td>
        <td align="center">
          <% $$_[1] %>
        </td>
      </tr>
% }
    </table>
<%perl>
  }

</%perl>
</%method>

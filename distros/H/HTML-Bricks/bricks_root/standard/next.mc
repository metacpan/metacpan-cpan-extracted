%#----------------------------------------------------------------------------
%# File: next
%# 
%# link to the next matching assembly, if no more matches, link to mason/pure
%# html file.  If no mason/html file, then don't link to anything.
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my ($rbrick) = @_;
  my $rdata = $$rbrick{data};

  $$rdata{rfilelink} = HTML::Bricks::fetch('filelink');
  $$rdata{rfilelink}->new();
  
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# get_edit_lists
%#----------------------------------------------------------------------------
<%method get_edit_lists>
<%perl>
  my ($rbrick, $route_tag, $edit_tag, $rpositions, $rdestinations) = @_;
 
  my $rdata = $$rbrick{data};
  my $rnext_brick = $$rdata{rnext_brick};

  if (defined $rnext_brick) {
    $rnext_brick->get_edit_lists($route_tag,$edit_tag,$rpositions,$rdestinations);
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# set_next
%#----------------------------------------------------------------------------
<%method set_next>
<%perl>
  my ($rbrick, $rnext_brick) = @_;
 
  my $rdata = $$rbrick{data};
  $$rdata{rnext_brick} = $rnext_brick;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# get_next
%#----------------------------------------------------------------------------
<%method get_next>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};
  return $$rdata{rnext_brick};
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# get_modified
%#----------------------------------------------------------------------------
<%method get_modified>
<%perl>
  my ($rbrick) = @_;
  my $rdata = $$rbrick{data};
  
  if (defined $$rdata{rnext_brick}) {
    return $$rdata{rnext_brick}->get_modified();
  }

  return undef;
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# freeze
%#----------------------------------------------------------------------------
<%method freeze>
<%perl>
  my ($rbrick, $rsub) = @_;

  my $rdata = $$rbrick{data};

  if ((defined $rsub) && (defined $$rdata{rnext_brick})) {
    &$rsub($$rdata{rnext_brick});
  }

  return { name => $$rbrick{name}, data => { frozen_filelink => $$rdata{rfilelink}->freeze() } };

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# thaw
%#----------------------------------------------------------------------------
<%method thaw>
<%perl>
  my ($rbrick, $rnode) = @_;

  my $rdata = $$rbrick{data};
  my $rnode_data = $$rnode{data};

  $$rdata{rfilelink} = HTML::Bricks::fetch('filelink');
  $$rdata{rfilelink}->thaw($$rnode_data{frozen_filelink});

  return $rbrick;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# walk
%#----------------------------------------------------------------------------
<%method walk>
<%perl>
  my ($rbrick, $walk_comp, $recurse) = @_;

  my $rdata = $$rbrick{data}; 
  my $rnext_brick = $$rdata{rnext_brick};

  if (defined $$rdata{rnext_brick}) {

    &$walk_comp($$rdata{rnext_brick});
    $rnext_brick->walk($walk_comp,$recurse); 

  }
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# save
%#----------------------------------------------------------------------------
<%method save>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};
  my $rnext_brick = $$rdata{rnext_brick};

  if (defined $rnext_brick) {
    $rnext_brick->save();  
  }

  delete $$rdata{modified};

  return { name => 'next', data => {} };

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# route_sub
%#----------------------------------------------------------------------------
<%method route_sub>
<%perl>
  my ($rbrick, $destination, $sub) = @_;

  my $rdata = $$rbrick{data}; 
  my $rnext_brick = $$rdata{rnext_brick};

  if (defined $rnext_brick) {
    return $rnext_brick->route_sub($destination, $sub);
  }
  else {
    print STDERR "next:route_sub: no next brick\n";
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# edit
%#----------------------------------------------------------------------------
<%method edit>
<%perl>
  my ($rbrick,$rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) = @_;
</%perl>

<form method="post" action="<% $$ruri %>">
  Assylink links to the next matching assembly. There is nothing to edit here.
  <p>
  <input type="submit" value="ok">
</form>
</%method>
 
%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick,$rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) = @_;
  my $rdata = $$rbrick{data};

  my $r = Apache->request;

  #
  # grab the mode from the session data
  #
  # why?  well, it's possible that this assembly (the one
  # next is a part of, has edit off even though we're in 
  # edit mode.  For example, the authorbar isn't in edit
  # mode, since it's the edit menu.
  #

  $mode = $HTML::Bricks::session{mode};

  #
  # process commands
  #

  if (defined $HTML::Bricks::session{username}) {

    #
    # Administrator logged in, process link command
    #

    my $linkname = $r->uri;

    if ($$rARGS{fn} eq 'create_assy') {

      #
      # create an empty assembly
      #

      my $path = HTML::Bricks::get_user_bricks_path();

      my $rmatch_brick = HTML::Bricks::fetch('assembly');
      $rmatch_brick->new();
      $rmatch_brick->set_save_name($path . '/' . $$rARGS{filename});
      $rmatch_brick->save();

      #
      # create a mapping for the assembly
      #

      my %mapping;

      my $n = rindex($linkname,'/') + 1;
      $mapping{folder} = substr($linkname,0,$n);
      $mapping{match_string} = substr($linkname, $n, length($linkname) - $n);
      $mapping{recurse} = 'n';
      $mapping{match_type} = 'string';
      $mapping{brick_name} = $$rARGS{filename};

      use HTML::Bricks::Mappings;
      my $mapper = HTML::Bricks::Mappings->new();

      $mapper->insert(-1,\%mapping);

      #
      # link the assembly
      #

      $rbrick->set_next($rmatch_brick);
    }
    elsif ($$rARGS{fn} eq 'map_assy') {

      my %mapping;

      my $n = rindex($linkname,'/') + 1;

      $mapping{folder} = substr($linkname,0,$n);
      $mapping{match_string} = substr($linkname, $n, length($linkname) - $n);
      $mapping{recurse} = 'n';
      $mapping{match_type} = 'string';
      $mapping{brick_name} = $$rARGS{assy};

      use HTML::Bricks::Mappings;
      my $mapper = HTML::Bricks::Mappings->new();

      $mapper->insert(-1,\%mapping);

      my $rmatch_brick = HTML::Bricks::fetch($$rARGS{assy});
      $rmatch_brick->new();
      $rbrick->set_next($rmatch_brick);
    }
    elsif ($$rARGS{fn} eq 'create_file') {
      my $n = rindex($linkname,'/') + 1;

      my $folder = substr($linkname,0,$n);
      my $filename = substr($linkname, $n, length($linkname) - $n);

      #
      # traverse the folder, trying to create as we go
      #

      my $curr = $r->document_root;

      while ($linkname =~ /([^\/]+)(\/.*)$/) {
        $curr .= "/$1";
        $linkname = $2;
 
        if (-e $curr) {
 
          if (!-d $curr) {
            print STDERR "next: could not create file for $curr because a non-directory file of that name already exists\n";
            return;
          }
            
          next;
        }

        mkdir($curr) || print STDERR "next: mkdir for $curr failed\n";
      } 

      $curr .= $linkname; 

      open(FILE,"> $curr") || die "couldn't open $curr for output";
      print FILE "This file, $curr, intentionally left blank<br>\n";
      close(FILE);
    }
  }

  if (!defined $$rdata{rnext_brick}) {

    #
    # no assembly, so link to a file
    #

    my $sub_route_tag = (defined $route_tag) ? "$route_tag.1" : "1";

    my $ra = $$rsub_ARGS{1};
    my $sroute_tag = ($route_tag eq '') ? '1' : $route_tag . '.1';

    $$rdata{rfilelink}->set_link($r->uri);
    $$rdata{rfilelink}->set_load(0);
    $$rdata{rfilelink}->process($rbrick,$rroot_brick,$$ra{rARGS},$$ra{rsub_ARGS},$sroute_tag,$ruri,$mode,$rredirect);
  }
  else {

    if (($mode eq 'edit') && ($$rARGS{fn} eq 'edit')) {
      $$rredirect = sub { $rbrick->edit($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
    }

    #
    # pass on arguments to any sub-assemblies
    #

    foreach (keys %HTML::Bricks::global_args) {
      $$rsub_ARGS{$_} = $HTML::Bricks::global_args{$_};
    }

    ${$$rdata{rnext_brick}}{rparent} = $rbrick;

    $$rdata{rnext_brick}->process($rbrick, $rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect);
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render
%#----------------------------------------------------------------------------
<%method render>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode) = @_;

  my $r = Apache->request;
  my $rdata = $$rbrick{data};

  $mode = $HTML::Bricks::session{mode};

  if (defined $$rdata{rnext_brick}) {

    #
    # we have an assembly, so render it 
    #
   
    foreach (keys %HTML::Bricks::global_args) {
      $$rARGS{$_} = $HTML::Bricks::global_args{$_};
    }

    $$rdata{rnext_brick}->render($rbrick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode);
  }
  else {

    #
    # no assembly, so link to a file
    #

    my $sub_route_tag = (defined $route_tag) ? "$route_tag.1" : "1";
    my $stag = (defined $edit_tag) ? "$edit_tag.1" : '1';

    #
    # first we try fetch_next, if that doesn't work, explicitly 
    # fetch the comp.  This is necessary in cases where we just
    # created the file in process.
    #

    my $filename = $r->document_root . '/' . $r->uri;

    if (-e $filename) {

      if ($mode eq 'edit') {
        $m->comp("/editmisc:render_header",
          brick_name => "filelink",
          brick_notes => undef,
          route_tag => $sub_route_tag,
          uri => $uri,
          edit_tag => $stag);
      }

      $$rdata{rfilelink}->set_link($r->uri);
      $$rdata{rfilelink}->set_load(0);

      my $ra = $$rsub_ARGS{1};

      my $sroute_tag = ($route_tag eq '') ? '1' : $route_tag . '.1';

      $$rdata{rfilelink}->render($rroot_brick, $$ra{rARGS}, $$ra{rsub_ARGS}, $sroute_tag, $edit_tag, $uri, $mode);

    }
    elsif (defined $HTML::Bricks::session{username}) {

      if ($r->uri =~ /.*new_brick.html/) {
        $m->out("[ no next assembly ]\n");
        next;
      }

      #
      # No file and administrator logged in, put up the "create 404"
      #

      my $linkname = $r->uri;
      my $rassemblies = HTML::Bricks::get_assemblies_list(); 

      my @locations;

      #
      # strip off any prepended and file extensions from the uri
      #

      my $i = rindex($r->uri,'/')+1;
      my $naked_uri = substr($r->uri,$i,length($r->uri)-$i);
      $i = rindex($naked_uri,'.');
      if ($i != -1) { $naked_uri = substr($naked_uri,0,$i) };

</%perl>
      <br>
      <b>404 Not found</b>
      <p>
      The requested URI <% $linkname %> was not found on this server.
      <p>
      <form method="post" action="<% $uri %>">
        <input type="hidden" name="<% $route_tag %>:fn" value="create_assy">
        Create an assembly that maps to this URI named
        <br>
        <table border="0">
          <tr>
            <td>
              <input type="text" name="<% $route_tag %>:filename" value="<% $naked_uri %>">
            </td>
            <td>
              <input type="submit" value="create">
            </td>
          </tr>
        </table>
      </form>
      <form method="post" action="<% $uri %>">
%       if ($#$rassemblies != -1) {
          <input type="hidden" name="<% $route_tag %>:fn" value="map_assy">
          Map an assembly to this URI named
          <table border="0">
            <tr>
              <td>
                <select name="<% $route_tag %>:assy">
%               foreach (@$rassemblies) {
                  <option value="<% $_ %>"><% $_ %>
%               }
              </td>
              <td colspan="2" align="right">
                <input type="submit" value="map">
              <td>
            </tr>
          </table>
%       }
      </form>
      Or create a <a href="<% $uri %><% $route_tag %>:fn=create_file">file</a> that maps to this URI.
      <br>
<%perl>
    }
    else {

      #
      # not found, administrator not logged in, so ignore.
      #

    }
  }
</%perl>
</%method>

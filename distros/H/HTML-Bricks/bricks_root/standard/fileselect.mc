%#----------------------------------------------------------------------------
%# File: fileselect
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my ($rbrick, $rtype, $root_dir, $rfilename, $rreturn) = @_;

  my $rdata = $$rbrick{data};

  $$rdata{rfilename} = $rfilename;
  $$rdata{rreturn} = $rreturn;

  $$rdata{type} = $rtype;
  $$rdata{root_dir} = $root_dir;
  $$rdata{rdests} = [ '/' ];
  $$rdata{rtypes} = [ [ '.*', 'all files' ] ];
  $$rdata{folder_mode} = 'list';

  $$rdata{filter} = '.*';

  if (defined $rfilename) {
    my $i = rindex(${$$rdata{rfilename}},'/') + 1;

    $$rdata{path} = substr(${$$rdata{rfilename}}, 0, $i-1); 
    $$rdata{name} = substr(${$$rdata{rfilename}}, $i, length(${$$rdata{rfilename}}) - $i);
  }

</%perl>
</%method>

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
%# freeze
%#----------------------------------------------------------------------------
<%method freeze>
<%perl>
  my $rbrick = shift;
  my $rdata = $$rbrick{data};

  my %node;
  $node{name} = $$rbrick{name};
  my $rnode_data = $node{data} = {};

  %$rnode_data = %$rdata;

  delete $$rnode_data{rfilename};
  delete $$rnode_data{rreturn};

  return \%node;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# thaw
%#----------------------------------------------------------------------------
<%method thaw>
<%perl>
  my ($rbrick,$rnode,$root_dir,$rfilename,$rreturn) = @_;

  $rbrick->new();

  my $rdata =  $$rbrick{data};

  %{$$rbrick{data}} = %{$$rnode{data}};
  $$rdata{rfilename} = $rfilename;
  $$rdata{rreturn} = $rreturn;
  $$rdata{root_dir} = $root_dir;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $r = Apache->request;
  my $rdata = $$rbrick{data};
  delete $$rdata{input_error};

  if (defined $$rARGS{folder_mode}) {
    $$rdata{folder_mode} = $$rARGS{folder_mode};
  }

  if (defined $$rARGS{open}) {

    $$rdata{name} = $$rARGS{name};

    if ($$rARGS{name} !~ /\/(.*)/) {
      ${$$rdata{rfilename}} = $$rdata{path} . '/' . $$rARGS{name};
    }
    else {
      ${$$rdata{rfilename}} = $$rARGS{name};
    }

    if (! -e $$rdata{root_dir} . '/' . ${$$rdata{rfilename}}) {
      $$rdata{input_error} = 1;
      return;
    }

    ${$$rdata{rreturn}} = 'open'; 
  }
  elsif (defined $$rARGS{save}) {
    $$rdata{name} = $$rARGS{name};

    if ($$rARGS{name} !~ /\/(.*)/) {
      ${$$rdata{rfilename}} = $$rdata{path} . '/' . $$rARGS{name};
    }
    else {
      ${$$rdata{rfilename}} = $1;
    }

    my $path = substr($$rARGS{name}, 0, rindex('/' . $$rARGS{name},'/'));
    if (! -d $$rdata{root_dir} . '/' . $path) {
      $$rdata{input_error} = 1;
      return;
    }

    ${$$rdata{rreturn}} = 'save'; 
  }
  elsif (defined $$rARGS{cancel}) {
    ${$$rdata{rreturn}} = 'cancel';
  }
  elsif (defined $$rARGS{name}) {
    my $full = $$rdata{root_dir} . "/" . $$rdata{path} . "/" . $$rARGS{name};
 
    if (-d $full) {
      $$rdata{path} .= '/' . $$rARGS{name};
      $$rdata{name} = '';
    }
    else { 
      $$rdata{name} = $$rARGS{name};
      if ($$rdata{type} eq 'open') {
        ${$$rdata{rreturn}} = 'open'; 
      } 
      else {
        ${$$rdata{rreturn}} = 'save'; 
      }
    }
 
    ${$$rdata{rfilename}} = $$rdata{path} . '/' . $$rdata{name};
  }

  if (exists $$rARGS{up}) {
    my $pt = rindex($$rdata{path},'/');
    $$rdata{path} = substr($$rdata{path},0,$pt);
    $$rdata{name} = '';
    ${$$rdata{rfilename}} = $$rdata{path} . '/' . $$rdata{name};
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

  my ($submit_tag, $type_tag, $dest_tag);

  if ($$rdata{type} eq 'open') {
    $dest_tag = 'look in';
    $type_tag = 'files of type';
    $submit_tag = 'open';
  }
  else {
    $dest_tag = 'save in';
    $type_tag = 'save as';
    $submit_tag = 'save';
  }

  use Apache::File;

  my $fh = Apache::gensym();
  my $path = $$rdata{root_dir} . "/$$rdata{path}";

  opendir($fh,$path) || die "Can't open $path";
  my (@fs) = readdir($fh);
  closedir($fh);

  my @files;
 
  foreach (@fs) {
    if (($_ =~ $$rdata{filter}) && ($_ ne '.') && ($_ ne '..')) {
      my @stat_data = stat("$path/$_");
      my $flags = (-d "$path/$_" ) ? '<img src="/bricks_images/folder.gif"> ' : undef;

      my @lt = localtime($stat_data[9]);

      my $timestamp = sprintf("%d-%02d-%02d&nbsp;&nbsp;%02d:%02d:%02d",
        (1900 + $lt[5]),($lt[4]+1),$lt[3],$lt[2],$lt[1],$lt[0]);

      push @files, [ $flags, $_ , $stat_data[7] , $timestamp];
    }
  }

  my @sorted_files = sort { ($$a[0] eq $$b[0]) ? uc($$a[1]) cmp uc($$b[1]) : (defined $$a[0]) ? -1 : 1 } @files;

</%perl>
  
<table border="1" cellpadding="0" cellspacing="0">
  <tr>
    <td align="left">
      folder: <% $$rdata{path} %>
    </td>
  </tr>
  <tr>
    <td>

  <table width="100%" border="0">
    <tr>
%#      <td>
%#        <% $dest_tag %>
%#        <select onchange="submit()" name="dest">
%#       foreach (@{$$rdata{rdests}}) {
%#          <option value="<% $_ %>"><% $_ %>
%#       }
%#        </select>
%#        <noscript>
%#          <input type="submit" value="go">
%#        </noscript>
%#      </td>
      <td align="right">
%       if (($$rdata{path} ne '/') && ($$rdata{path} ne '')) {
          <a href="<% $uri %><% $route_tag %>:up">up</a>
%       } else {
          up
%       }
%#        <a href="<% $uri %><% $route_tag %>:new_folder">new folder</a>
%#        &nbsp;&nbsp;
%       if ($$rdata{folder_mode} ne 'list') {
          <a href="<% $uri %><% $route_tag %>:folder_mode=list">list</a>
%       } else {
          list
%       }
%       if ($$rdata{folder_mode} ne 'details') {
          <a href="<% $uri %><% $route_tag %>:folder_mode=details">details</a>
%       } else {
          details
%       }

      </td>
    </tr>
  </table>

  <br>
  <form method="post" action="<% $uri %>">
    <table width="100%" border="1" cellspacing="0" cellpadding="0">
      <tr> 
        <td>
          <table width="100%" border="0">
%           if ($$rdata{folder_mode} eq 'list') {
%             foreach (@sorted_files) {
              <tr>
                <td>
                  <% $$_[0] %><a href="<% $uri %><% $route_tag %>:name=<% $$_[1] %>"><% $$_[1] %></a>
                </td>
              </tr>
%             }  
%           } else {
              <tr>
                <td> 
                  name 
                </td>
                <td align="right"> 
                  size
                </td>
                <td>
                  &nbsp;
                </td>
                <td>
                  modified
                </td>
              </tr>
%             foreach (@sorted_files) {
              <tr>
                <td>
                  <% $$_[0] %><a href="<% $uri %><% $route_tag %>:name=<% $$_[1] %>"><% $$_[1] %></a>
                </td>
                <td align="right">
                  <% $$_[2] %>
                </td>
                <td>
                  &nbsp;
                </td>
                <td>
                  <% $$_[3] %>
                </td>
              </tr>
%           }
%         }
          </table>
        </td>
      </tr>
    </table>
    <table width="100%" border="0">
    <tr>
      <td>
        file name:
        <input type="text" name="<% $route_tag %>:name" value="<% $$rdata{name} %>" size="60">
%       if (defined $$rdata{input_error}) {
          <br>
          <b>Error: invalid filename</b>
          <br>
%       }
%#        <br>
%#        <% $type_tag %>
%#        <select name="<% $route_tag %>:type">
%#%       foreach (@{$$rdata{rtypes}}) {
%#          <option value="<% $$_[0] %>"><% $$_[1] %>
%#%       }
%#        </select>
      </td>
      <td align="right">
%       if ($$rdata{type} eq 'open') {
          <input type="submit" name="<% $route_tag %>:open" value="<% $submit_tag %>">
%       } else {
          <input type="submit" name="<% $route_tag %>:save" value="<% $submit_tag %>">
%       }
        <br>
        <input type="submit" name="<% $route_tag %>:cancel" value="cancel">
      </td>
    </tr>
  </form>
  </tr>
</table>
</%method>

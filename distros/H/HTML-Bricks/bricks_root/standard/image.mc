%#----------------------------------------------------------------------------
%# File: image
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};

  $$rdata{rprops} = {};
  $$rdata{filename} = '';
  $$rdata{return} = undef;

  $$rdata{rfile_open} = HTML::Bricks::fetch('fileselect');
  $$rdata{rfile_open}->new('open', $HTML::Bricks::Config{document_root}, \$$rdata{filename}, \$$rdata{return});

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
  my $rbrick_data = $$rbrick{data};

  $$rnode_data{filename} = $$rbrick_data{filename};
  $$rnode_data{mode} = $$rbrick_data{mode};

  %{$$rnode_data{rprops}} = %{$$rbrick_data{rprops}};
  
  $$rnode_data{frozen_file_open} = $$rbrick_data{rfile_open}->freeze();

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

  my $rdata = $$rbrick{data}; 
  my $rnode_data = $$rnode{data};

  %{$$rdata{rprops}} = %{$$rnode_data{rprops}};
  $$rdata{mode} = $$rnode_data{mode};

  $$rdata{filename} = $$rnode_data{filename};
  $$rdata{return} = undef;

  $$rdata{rfile_open} = HTML::Bricks::fetch('fileselect');
  $$rdata{rfile_open}->thaw($$rnode_data{frozen_file_open}, $HTML::Bricks::Config{document_root}, \$$rdata{filename}, \$$rdata{return});

  return $rbrick;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render_edit($rARGS, $rbrick)
%#----------------------------------------------------------------------------
<%method render_edit>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};

  if ($$rdata{mode} eq 'select') {
    $$rdata{rfile_open}->render($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$$ruri,$mode);
    return;
  }

  my $rprops = $$rdata{rprops};

</%perl>
<b>image properties</b>
<p>
<form method="post" action="<% $$ruri %>">
  <input type="hidden" name="<% $route_tag %>:fn" value="edit_submit">

  URI of image: 
  <br>
  <input type="text" name="<% $route_tag %>:uri" value="<% $$rdata{filename} %>" size="70">
  <input type="submit" name="<% $route_tag %>:select" value="select">
  <table border="0">
%   foreach (@props) {
      <tr>
        <td align="right">
          <% $_ %>
        </td>
        <td>
          <input type="text" name="<% $route_tag %>:<% $_ %>" value="<% $$rprops{$_} %>">
        </td>
      </tr>
%   }
  </table>
  <p>
  <input type="submit" value="update">
  <input type="reset" value="reset">
</form>
</%method>

%#----------------------------------------------------------------------------
%# process($rARGS, $rbrick)
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};

  if ($mode eq 'edit') {

    if (defined $$rARGS{select}) {
      $$rdata{mode} = 'select';
      $rparent_brick->set_modified();
    }

    if ($$rdata{mode} eq 'select') {

      $$rdata{rfile_open}->process($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect);

      if (defined $$rdata{return}) { 
        delete $$rdata{mode};
        $$rdata{return} = undef;
        $$rARGS{fn} = 'edit';  # TODO: unkludge
      }

      $$rredirect = sub { $$rdata{rfile_open}->render($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,'',$$ruri,$mode); }

    }

    if ($$rARGS{fn} eq 'edit') {
      $$rredirect = sub { $rbrick->render_edit($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect); }
    }
    elsif ($$rARGS{fn} eq 'edit_submit') {
      my $rprops = $$rdata{rprops};
      foreach (@props) {
        if ($$rARGS{$_} ne '') {
          $$rprops{$_} = $$rARGS{$_};
        }
        else {
          delete $$rprops{$_};
        }
      }

      $rparent_brick->set_modified();
      $$rdata{filename} = $$rARGS{uri};
    }

  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render($rARGS, $rbrick)
%#----------------------------------------------------------------------------
<%method render>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode) = @_;

  my $rdata = $$rbrick{data};

  if ($$rdata{filename} ne '') {
    my $rprops = $$rdata{rprops};
    my $tag = "<img src=\"$$rdata{filename}\"";
    
    foreach (@props) {
      if (defined $$rprops{$_}) {
        $tag .= " $_=\"$$rprops{$_}\"";
      } 
    }

    $tag .= ">\n";
    $m->out($tag);
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
<%once>

  my @props = ('width','height','border','class');

</%once>


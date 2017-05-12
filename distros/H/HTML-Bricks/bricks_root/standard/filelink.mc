%#----------------------------------------------------------------------------
%# File: filelink
%# 
%# Links to a mason component or html file on disk.  Arguments are top_args.
%#
%# This brick is dedicated to Korn's album "You cannot sedate all the things
%# you hate."  Or, at least, it should've been dedicated to that album.  You
%# see, that's what the CD said it was when I bought it from a street vendor
%# in Beijing.  Unfortunately, my one dollar instead bought me Enigma's 
%# unremarkable third album.  So, I should dedicate it to Enigma, but would
%# still rather dedicate it to Korn.
%#
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};

  $$rdata{load} = 1;

  $$rdata{filename} = '';
  $$rdata{return} = undef;

  $$rdata{rfile_open} = HTML::Bricks::fetch('fileselect');
  $$rdata{rfile_open}->new('open', $HTML::Bricks::Config{document_root}, \$$rdata{filename}, \$$rdata{return});
  $$rdata{rfile_save_as} = HTML::Bricks::fetch('fileselect');
  $$rdata{rfile_save_as}->new('save_as', $HTML::Bricks::Config{document_root}, \$$rdata{filename},\$$rdata{return});

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

  my $rffile_open = $$rdata{rfile_open}->freeze();
  my $rffile_save_as = $$rdata{rfile_save_as}->freeze();

  %$rnode_data = %$rdata;
  $$rnode_data{frozen_file_open} = $rffile_open;
  $$rnode_data{frozen_file_save_as} = $rffile_save_as;
  delete $$rnode_data{rfile_open};
  delete $$rnode_data{rfile_save_as};

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

  return if !defined $rnode;  # TODO: remove this for 0.03 -- it shouldn't be needed then

  my $rdata = $$rbrick{data}; 
  my $rnode_data = $$rnode{data};

  %$rdata = %$rnode_data;

  $$rdata{rfile_open} = HTML::Bricks::fetch('fileselect');
  $$rdata{rfile_open}->thaw($$rnode_data{frozen_file_open},$HTML::Bricks::Config{document_root},\$$rdata{filename},\$$rdata{return});
  $$rdata{rfile_save_as} = HTML::Bricks::fetch('fileselect');
  $$rdata{rfile_save_as}->thaw($$rnode_data{frozen_file_save_as},$HTML::Bricks::Config{document_root},\$$rdata{filename},\$$rdata{return});

  delete $$rdata{frozen_file_open};
  delete $$rdata{frozen_file_save_as};

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# set_link
%#----------------------------------------------------------------------------
<%method set_link>
<%perl>
  my ($rbrick, $name) = @_;

  my $rdata = $$rbrick{data};
  $$rdata{filename} = $name;
  delete $$rdata{data};
</%perl>
</%method>
 
%#----------------------------------------------------------------------------
%# set_load
%#----------------------------------------------------------------------------
<%method set_load>
<%perl>
  my ($rbrick, $value) = @_;

  my $rdata = $$rbrick{data};
  $$rdata{load} = $value;
</%perl>
</%method>
 
%#----------------------------------------------------------------------------
%# render_edit
%#----------------------------------------------------------------------------
<%method render_edit>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  use Apache::Util;

  my $r = Apache->request;
  my $rdata = $$rbrick{data};

  #
  # load the file from disk if we need to
  #
  if (($$rdata{filename} ne '') && (!exists $$rdata{data})) {
    my @lines;
    open(FILE,'< ' . $r->document_root . '/' . $$rdata{filename});
    @lines = <FILE>;
    close(FILE);
    $$rdata{data} = join('',@lines);
  }

  if ($$rdata{mode} eq 'select') {
    $$rdata{rfile_open}->render($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, '', $$ruri, $mode);
    return;
  }
  elsif ($$rdata{mode} eq 'save as') {
    $$rdata{rfile_save_as}->render($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, '', $$ruri, $mode);
    return;
  }

</%perl>
<form method="post" action="<% $$ruri %>">
  <b>filelink properties</b>
  <p>
% if ($$rdata{load}) {
%   if ($$rdata{filename} ne '') {
      Currently linked to "<% $$rdata{filename} %>".
%   } else {
      Not currently linked to a file.
%   }
    <p>
    <input type="submit" name="<% $route_tag  %>:submit" value="select">
    <input type="submit" name="<% $route_tag  %>:submit" value="new">
    <input type="submit" name="<% $route_tag  %>:submit" value="return">
    <p>
% }
% if (defined $$rdata{data}) {

    <table border="0">
      <tr>
        <td>
%         if ($$rdata{filename} ne '') {
            editing file: <% $$rdata{filename} %>
%         } else {
            editing new file
%         }
%         if (defined $$rdata{input_error}) {
            <br>
            <b>Error: the file name is not valid</b>
            <br>
%         }
        </td>
        <td align="right">
          <input type="submit" name="<% $route_tag  %>:save_changes" value="save">
          <input type="submit" name="<% $route_tag  %>:submit" value="save as">
          <input type="reset" value="reset">
          <input type="submit" name="<% $route_tag  %>:submit" value="return">
        </td>
      </tr>
      <tr>
        <td colspan="2">
          <textarea name="<% $route_tag %>:data" rows="30" cols="70"><% Apache::Util::escape_html($$rdata{data}) %></textarea>
        </td>
      </tr>
      <tr>
        <td colspan="2" align="right">
          <table cellspacing="0" cellpadding="0" border="0">
            <tr>
              <td>
                <input type="submit" name="<% $route_tag  %>:save_changes" value="save">
                <input type="submit" name="<% $route_tag  %>:submit" value="save as">
                <input type="reset" value="reset">
                <input type="submit" name="<% $route_tag  %>:submit" value="return">
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
% }
</form>
</%method>
 
%#----------------------------------------------------------------------------
%# save_changes_ma
%#----------------------------------------------------------------------------
<%method save_changes_ma>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;
  my $rdata = $$rbrick{data};
</%perl>
<form method="post" action="<% $$ruri %>">
  <b>filelink save</b>
  <p>
% if (defined $$rdata{filename}) {
  Save changes to <% $$rdata{filename} %>?
% } else {
  Save changes?
% }
  <p>
  <input type="submit" name="<% $route_tag %>:save_changes" value="yes">
  <input type="submit" value="no">
</form>
</%method>

%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $r = Apache->request;
  my $rdata = $$rbrick{data};

  $$rdata{new_data} = $$rARGS{data} if defined $$rARGS{data};

  #
  # load the file from disk if we need to
  #

  if (($$rdata{filename} ne '') && (!exists $$rdata{data})) {
    my @lines;
    open(FILE,'< ' . $r->document_root . '/' . $$rdata{filename});
    @lines = <FILE>;
    close(FILE);
    $$rdata{data} = join('',@lines);
  }

  if ($mode eq 'edit') {

    #
    # if the user selects properties edit, redirect and return to get us going
    #

    if ($$rARGS{fn} eq 'edit') {

      $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, 
                          $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };
      return;
    }

    #
    # Process input from a modal open or save as dialog
    #

    if ($$rdata{mode} eq 'select') {
      
      #
      # we're always redirecting when $$rdata{mode} eq 'select'
      #

      $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, $rARGS, 
                          $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };

      #
      # process input from the previous call
      #

      $$rdata{rfile_open}->process($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, 
                                   $route_tag, '', $$ruri, $mode, $rredirect);

      #
      # see if the user wants to return from the fileselect
      #

      if (defined $$rdata{return}) {

        if ($$rdata{return} eq 'open') {

          #
          # user pressed 'open' -- read in the file
          #

          my @lines;
          open(FILE,'< ' . $r->document_root . '/' . $$rdata{filename});
          @lines = <FILE>;
          close(FILE);
          $$rdata{data} = join('',@lines);
          delete $$rdata{modified};
        }

        # 
        # exit from the fileselect and undef 'return'
        #

        delete $$rdata{mode}; 
        $$rdata{return} = undef;
      }
      else {

        #
        # still in fileselect
        #

        return;
      }
    }
    elsif ($$rdata{mode} eq 'save as') {
 
      #
      # Unless this dialog was brought up because the user pressed return, set redirect
      #
## ???
      if ($$rdata{op} ne 'return') {
        $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, $rARGS, 
                            $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };
      }

      #
      # process input from the previous call
      #

      my $old_filename = $$rdata{filename};

      $$rdata{rfile_save_as}->process($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, 
                                      $route_tag, '', $$ruri, $mode, $rredirect);

      if (defined $$rdata{return}) {

        if ($$rdata{return} eq 'save') {

          # 
          # user pressed 'save' -- write the file
          #

          my $f = $r->document_root . '/' . $$rdata{filename};
          open(FILE, "> $f") || die "could not open $f for output";
          print FILE $$rdata{data};
          close(FILE);
          delete $$rdata{modified};
          $$rdata{filename} = $old_filename;
        }

        # 
        # exit from the fileselect and undef 'return'
        #

        delete $$rdata{mode}; 
        $$rdata{return} = undef;
      }
      else {

        #
        # still in fileselect
        #

        return;
      }

    }

    #
    # user pressed a button or reloaded the page
    #

    if (($$rARGS{submit} eq 'save as')  || ((defined $$rARGS{save_changes}) && ($$rdata{filename} eq ''))){

      #
      # do a 'save as'
      #

      $$rdata{mode} = 'save as';           # set the mode

      $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };

      return;
    }
    elsif (defined $$rARGS{save_changes}) {

      #
      # Unless this dialog was brought up because the user pressed return, set redirect
      #

      if ($$rdata{op} ne 'return') {
        $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };
      }

      #
      # save the file and continue
      #

      my $f = $r->document_root . '/' . $$rdata{filename};
      open(FILE, "> $f") || die "could not open $f for output";
      print FILE $$rdata{new_data}; # got here via 'save changes ma'
      close(FILE);

      $$rdata{data} = $$rdata{new_data};
      delete $$rdata{new_data};

      return;
    }
    else {

      #
      # user isn't in modal dialog, and user doesn't want to save
      #

      #
      # if we went through a modal dialog, the {submit} value was stored in rdata
      #

      if (defined $$rdata{op}) {
        $$rARGS{submit} = $$rdata{op};
        delete $$rdata{op};
      }

      if ((defined $$rARGS{data}) && ($$rdata{data} ne $$rARGS{data})) {

        #
        # if the data has been modified, redirect to "save changes?"
        #

        $$rdata{op} = $$rARGS{submit};
        $$rredirect = sub { $rbrick->save_changes_ma($rparent_brick, $rroot_brick, 
                            $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };
        return;
      }

      if ($$rARGS{submit} eq 'select') {
        # 
        # user wants to select a file
        #

        $$rdata{data} = undef;
        $$rdata{mode} = 'select';
        $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, 
                            $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };
        return;
      }
      elsif ($$rARGS{submit} eq 'new') {
        #
        # user wants to create a file
        #

        $$rdata{filename} = '';
        $$rdata{data} = '';
        $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, 
                            $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };
        return;
      }
      elsif ($$rARGS{submit} eq 'return') {
        #
        # user wants to return from editing properties
        #

        delete $$rdata{data};
      }
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

  return unless defined $$rdata{filename};

  my $r = Apache->request;
  my $filename = $r->document_root . '/' . $$rdata{filename};

  return if ((-d $filename) || (! -e $filename));

#  $m->comp($$rdata{filename});

  my @lines;
  open(FILE,'< ' . $r->document_root . '/' . $$rdata{filename});
  @lines = <FILE>;
  close(FILE);
  $m->out(join('',@lines));

</%perl>
</%method>


%#---------------------------------------------------------------------------
%# File: assembly
%#
%# Derived from the column class.
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my ($rbrick) = @_;

  $rbrick->push_supers('column');
  $rbrick->super->new();

  my $rdata = $$rbrick{data};

  my $name = ${${$$rbrick{rsuper_class_data}}[0]}{filename};

  if ($name =~ /.*\/assembly.mc/) {
    $name = '/user/';
  }

  $$rdata{filename} = $name;

  $$rdata{return} = undef;

  $$rdata{rfile_save_as} = HTML::Bricks::fetch('fileselect');
  $$rdata{rfile_save_as}->new('save_as', $HTML::Bricks::Config{bricks_root}, \$$rdata{filename}, \$$rdata{return}); 

  $$rdata{rprops} = {};
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
%# is_assembly
%#----------------------------------------------------------------------------
<%method is_assembly>
<%perl>
  return 1;
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# is_blank
%#----------------------------------------------------------------------------
<%method is_blank>
<%perl>
  my $rbrick = shift;
  my $rdata = $$rbrick{data};

  if (defined $$rdata{is_blank}) {
    delete $$rdata{is_blank};
    return 1;
  }

  return 0; 
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# set_id
%#----------------------------------------------------------------------------
<%method set_id>
<%perl>
  my ($rbrick, $rcurrent_brick) = @_;

  my $rdata = $$rbrick{data};
  my $id = $$rdata{next_id}++;
  $$rcurrent_brick{id} = $id;
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# set_save_name
%#----------------------------------------------------------------------------
<%method set_save_name>
<%perl>
  my ($rbrick, $name) = @_;

  # TODO: sort out mess with $$rdata{save_name} and $$rdata{filename}

  my $rdata = $$rbrick{data};
  $$rdata{filename} = $name;
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# get_assembly_props
%#
%# This is called in two different ways:
%#
%#   1. :render is called and this assembly calls its' own :get_assembly_props routine.
%#      Check the various cases and potentially call the children to get the
%#      assembly props from a sub-assembly.  This case should only be executed
%#      if there is no parent, because if there were a parent, it would 
%#      already have taken care of finding out what the assembly props are and 
%#      rendered them.  After all, there's only one <head> and <title> per page.
%#
%#   Which brings us to the second case:
%#
%#   2. :render was called on the top-level assembly and it was inheriting props
%#      from a sub-assembly, so it called its' parent object to get the props
%#      from the rest of the assembly.  (There is a difference between the parent
%#      object (in this case, a column) and the parent in the rendering order.)
%#
%#----------------------------------------------------------------------------
<%method get_assembly_props>
<%perl>
  my ($rbrick, $rprops) = @_;

  my $rdata = $$rbrick{data};
  my $rp = $$rdata{rprops};

  if ($$rp{use_props} eq 'parent') {
    return undef;
  }
  elsif ($$rp{use_props} eq 'child') {

    my @assys = $rbrick->super->find(1,'assembly','.*','.*','assembly');
    my $rassy;

    if ($#assys > 0) {
      $rassy = $assys[1];             
    }
    else {
      $rassy = $rbrick->get_next();
    }

    return 1 if defined $rassy and defined $rassy->get_assembly_props($rprops);
  }

  # 
  # if $$rp{use_props} eq 'self' or if it just exists, fill the hash
  #
 
  if (exists $$rp{use_props}) {
    %$rprops = %{$$rdata{rprops}};
    return 1;
  }

  return undef;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# get_label
%#----------------------------------------------------------------------------
<%method get_label>
<%perl>
  my ($rbrick) = @_;
  if ($$rbrick{name} ne 'assembly') {
    return ('assembly',$$rbrick{name});
  }
  else {
    return ('assembly',$$rbrick{save_name});
  }

</%perl>
</%method>


%#----------------------------------------------------------------------------
%# build_assemblies_list
%#----------------------------------------------------------------------------
<%method build_assemblies_list>
<%perl>
  my ($rbrick, $rcurrent_brick, $rassemblies) = @_;

  if ($rcurrent_brick->can('is_assembly')) {
    push @$rassemblies, $rcurrent_brick;
  }

  if ($$rcurrent_brick{name} eq 'next') {
    my $rnext = $rcurrent_brick->get_next();
 
    if (defined $rnext) {
      push @$rassemblies, $rnext;
    }
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# get_modified
%#----------------------------------------------------------------------------
<%method get_modified>
<%perl>
  my ($rbrick) = @_;
  my $rdata = $$rbrick{data};

  return 1 if $$rdata{modified};

  my @assemblies;

  $rbrick->walk(
    sub { 
      my $rcurrent = shift; 
      $rbrick->build_assemblies_list($rcurrent,\@assemblies); 
      return 1 }, 
    1);

  foreach (@assemblies) {
    return 1 if $_->get_modified(); 
  }

  return undef;
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# set_modified
%#----------------------------------------------------------------------------
<%method set_modified>
<%perl>
  my ($rbrick) = @_;
  my $rdata = $$rbrick{data};
  $$rdata{modified} = 1;

  $$rdata{save_name} = $$rbrick{name};
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# set_next
%#----------------------------------------------------------------------------
<%method set_next>
<%perl>
  my ($rbrick, $rnext_assembly) = @_;

  my $rdata = $$rbrick{data};

  if (!defined $$rdata{rnext_brick}) {
    my @nexts = $rbrick->find(1,'assembly','next');
    $$rdata{rnext_brick} = shift @nexts;
  }

  return if !defined $$rdata{rnext_brick};

  $$rdata{rnext_brick}->set_next($rnext_assembly);
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# get_next
%#----------------------------------------------------------------------------
<%method get_next>
<%perl>
  my ($rbrick) = @_;
  
  my $rdata = $$rbrick{data};

  return undef if !defined $$rdata{rnext_brick};

  return $$rdata{rnext_brick}->get_next();
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# freeze
%#----------------------------------------------------------------------------
<%method freeze>
<%perl>
  my ($rbrick, $rsub) = @_;

  my $rnode = $rbrick->super->freeze($rsub);

  $$rnode{name} = $$rbrick{name};

  my $rbrick_data = $$rbrick{data};

  return $rnode if !defined $$rbrick_data{rprops};

  my $rbrick_props = $$rbrick_data{rprops};

  my $rnode_data = $$rnode{data};

  $$rnode_data{filename} = $$rbrick_data{filename};
  $$rnode_data{mode} = $$rbrick_data{mode};
  $$rnode_data{modified} = $$rbrick_data{modified};
  $$rnode_data{prev_modified_defined} = $$rbrick_data{prev_modified_defined};
  $$rnode_data{frozen_file_save_as} = $$rbrick_data{rfile_save_as}->freeze();

  my $rnode_props = $$rnode_data{rprops} = {};

  if (defined $rbrick_props) { 
    %$rnode_props = %$rbrick_props;
  }

  return $rnode;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# thaw
%#----------------------------------------------------------------------------
<%method thaw>
<%perl>
  my ($rbrick, $rnode) = @_;

  $rbrick->push_supers('column');
  $rbrick->super->new();

  $rbrick->super->thaw($rnode);

  my $rbrick_data = $$rbrick{data};
  my $rbrick_props = $$rbrick_data{rprops} = {};

  my $rnode_data = $$rnode{data};
  my $rnode_props = $$rnode_data{rprops};

  if (defined $rnode_props) {
    %$rbrick_props = %$rnode_props;
  }

  $$rbrick_data{name} = $$rnode_data{name};
  $$rbrick_data{filename} = $$rnode_data{filename} if defined $$rnode_data{filename};
  $$rbrick_data{mode} = $$rnode_data{mode};
  $$rbrick_data{modified} = $$rnode_data{modified};
  $$rbrick_data{prev_modified_defined} = $$rnode_data{prev_modified_defined};

  $$rbrick_data{return} = undef;
  $$rbrick_data{rfile_save_as} = HTML::Bricks::fetch('fileselect');

  $$rbrick_data{rfile_save_as}->thaw($$rnode_data{frozen_file_save_as},$HTML::Bricks::Config{bricks_root},\$$rbrick_data{filename},\$$rbrick_data{return}) if defined $$rnode_data{frozen_file_save_as}; # TODO: remove in 0.03

  $rbrick->walk(sub { $rbrick->set_id(); }, 1);

  return $rbrick;

</%perl>
</%method>


%#----------------------------------------------------------------------------
%# save
%#----------------------------------------------------------------------------
<%method save>
<%perl>

  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};
  my $filename = $$rdata{filename};

  my $rnode = $rbrick->freeze(sub {
      my ($rb, $rsub) = @_;

      if (($rb->can('save')) && ($rb != $rbrick)) {
        return $rb->save();
      }
      elsif ($rb->can('freeze')) {
        return $rb->freeze($rsub);
      }
      else {
        my $rsub_node = {};
        my $VAR1;
        eval(Dumper($$rb{data}));
        $$rsub_node{data} = $VAR1;
        $$rsub_node{name} = $$rb{name};
        
        return $rsub_node;
      }
    });

  #
  # if this _specific_ assembly hasn't been modified, return
  #

  return { name => $$rbrick{name}, data => {} } unless $$rdata{modified};

  #
  # freeze the assembly into a node
  #

  my $rnode_data = $$rnode{data};
  delete $$rnode_data{filename};

  #
  # clear the modified flag
  #
  # If the modified flag isn't set when calling assy->freeze(), it returns a
  # blank node.  This is because if the node is blank, it's supposed to 
  # load from the disk image.  It's a kludge.
  #

  delete $$rdata{modified};
  delete $$rnode_data{modified};

  #
  # read /assembly_template into a string
  #

  my $infilename = $HTML::Bricks::Config{bricks_root} . '/assembly_template';
  open(FILE, "< $infilename") || die "can't open $infilename\n";
  my $infile = join("",<FILE>);
  close(FILE);

  #
  # write the output file
  #

  my $d = Data::Dumper->new([$rnode]);
  $d->Varname('rsaved_node');
  $d->Indent(1);
  $d->Useqq(0);

  my $outfilename = $HTML::Bricks::Config{bricks_root} . '/' . $filename;

  open(FILE, "> $outfilename") || die "can't open $outfilename for writing\n";
  print FILE "%#----------------------------------------------------------------------------\n";
  print FILE "%# brick: $$rbrick{name}\n";

  print FILE $infile;
  print FILE "<" . "%once>\n" . '  my ';
  print FILE $d->Dump();
  print FILE "<" . "/" . "%once>\n";            
  close(FILE);

  return { name => $$rbrick{name}, data => {} };
  
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render_props
%#----------------------------------------------------------------------------
<%method render_props>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  use Apache::Util;

  # munge the route tag because 'assembly' is a special case
  my $sroute_tag = (defined $route_tag) ? "$route_tag.0" : '0';

  my $rdata = $$rbrick{data};
  my $rprops = $$rdata{rprops};

  my $parent_sel = ($$rprops{use_props} eq 'parent') ? 'checked' : undef;
  my $child_sel  = ($$rprops{use_props} eq 'child') ? 'checked' : undef;
  my $self_sel;

  if ((! defined $parent_sel) && (!defined $child_sel)) {
    $self_sel = 'checked';
  }

  if (!defined $$rprops{doctype}) {
    $$rprops{doctype} = "HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\"";
  }

</%perl>

<b>assembly properties</b>


<form method="post" action="<% $$ruri %>">
  <input type="hidden" name="<% $sroute_tag %>:fn" value="process_props">
  <input type="radio" name="<% $sroute_tag %>:use_props" value="self" <% $self_sel %>>
  always use the properties below
  <br>
  <input type="radio" name="<% $sroute_tag %>:use_props" value="parent" <% $parent_sel %>>
  inherit properties from parent, use the properties below if no parent exists.
  <br>
  <input type="radio" name="<% $sroute_tag %>:use_props" value="child" <% $child_sel %>>
  inherit properties from child, use the properties below if no child exists
  <p>

  <table>
    <tr>
      <td align="right">
        doctype tag
      </td>
      <td>
        <input type="text" name="<% $sroute_tag %>:doctype" value="<% Apache::Util::escape_html($$rprops{doctype}) %>">
      </td>
    </tr>
    <tr>
      <td align="right">
        title tag
      </td>
      <td>
        <input type="text" name="<% $sroute_tag %>:title" value="<% Apache::Util::escape_html($$rprops{title}) %>">
      </td>
    </tr>
    <tr>
      <td align="right">
        body tag
      </td>
      <td>
        <input type="text" name="<% $sroute_tag %>:body" value="<% Apache::Util::escape_html($$rprops{body}) %>">
      </td>
    </tr>
    <tr>
      <td align="right" valign="top">
        meta tags
      </td>
      <td>
        <table border="0" cellspacing="0" cellpadding="0">
%         for (my $i=0; $i <= $#{$$rprops{rmetas}}; $i++) {
          <tr>
            <td>
              <% ${$$rprops{rmetas}}[$i] %>
            </td>
            <td>
              <a href="<% "$$ruri$sroute_tag" %>:del_meta=<% $i %>&<% $sroute_tag %>:fn=process_props">delete</a>
            </td>
          </tr>
%         }
%         if ($#{$$rprops{rmetas}} == -1) {
          <tr>
            <td colspan="2">
              (no metas)
            </td>
          </tr>
%         }
          <tr>
            <td>
              <input type="text" name="<% $sroute_tag %>:meta">
            </td>
            <td>
              <input type="submit" name="<% $sroute_tag %>:add_meta" value="add">
            </td>
          </tr>
        </table> 
      </td> 
    </tr>
  <table>
  <p>
  <input type="submit" name="<% $sroute_tag %>:submit" value="submit">
  <input type="reset" value="reset">
</form>
   
</form>

</%method>

%#----------------------------------------------------------------------------
%# save_as
%#----------------------------------------------------------------------------
<%method save_as>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};
  my $sroute_tag = (defined $$rdata{route_tag}) ? "$$rdata{route_tag}.0" : '0';
  $sroute_tag = (defined $route_tag) ? "$route_tag.0" : '0';

  $$rdata{rfile_save_as}->render($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $sroute_tag, undef, $$ruri, $mode);

  return;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# save_changes_ma
%#----------------------------------------------------------------------------
<%method save_changes_ma>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};
  my $sroute_tag = (defined $$rdata{route_tag}) ? "$$rdata{route_tag}.0" : '0';

  my $name = (defined $$rbrick{save_name}) ? $$rbrick{save_name} : $$rbrick{name};

</%perl>
<form method="post" action="<% $$ruri %>">
  <b>save assembly changes</b>
  <p>
  Save changes to <% $name %>?
  <p>
  <input type="submit" name="<% $route_tag %>:submit" value="yes">
  <input type="submit" name="<% $route_tag %>:submit" value="no">
</form>
</%method>

%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};

  if (($$rbrick{name} eq 'assembly') && (!defined $$rbrick{save_name})) {


    my @assemblies = $rbrick->super->find(1,'global','assembly.*');

    my $max = 0;

    foreach (@assemblies) {

      $$_{name} =~ /assembly(\d*)/;
      if ($1 > $max) {
        $max = $1;
      }

      $$_{save_name} =~ /assembly(\d*)/;
      if ($1 > $max) {
        $max = $1;
      }

    }

    $max++;
    $$rbrick{save_name} = "assembly$max";
  }

  my ($rsa, $ra);

  if (defined $$rsub_ARGS{0}) {
    $rsa = $$rsub_ARGS{0};
    $ra = $$rsa{rARGS};
  }
  else {
    $rsa = $rsub_ARGS;
    $ra = $rARGS;
  }

  if ($$rdata{mode} eq 'save_as') {

    my $sroute_tag = (defined $route_tag) ? "$route_tag.0" : '0';


    $$rdata{rfile_save_as}->process($rparent_brick,$rroot_brick,$ra,$rsub_ARGS,$sroute_tag,$ruri,$mode,$rredirect);

    if ($$rdata{return} eq 'save') { 
      my $old_modified = $$rdata{modified};
      my $old_name = $$rbrick{name};

      $$rdata{modified} = 1;
      
      $$rdata{filename} =~ /.*\/(.*).mc$/;
      $$rbrick{name} = $1;
      delete $$rdata{mode};
      $$rdata{return} = undef;
      $rbrick->save();

      $$rdata{modified} = $old_modified;
#      $$rbrick{name} = $old_name;

      if ($$rdata{prev_modified_defined} == -1) {
        $$rdata{modified} = undef;
        delete $$rdata{prev_modified_defined};
      }
    }
    elsif (defined $$rdata{return}) {
      delete $$rdata{mode};
      $$rdata{return} = undef;

      if ($$rdata{prev_modified_defined} == -1) {
        $$rdata{modified} = undef;
        delete $$rdata{prev_modified_defined};
      }
    }
    else {
      $$rredirect = sub { $rbrick->save_as($rparent_brick,$rroot_brick,$ra,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
    }


    return;
  }
  elsif ($$rdata{mode} eq 'save_changes_ma') {

    if ($$rARGS{submit} eq 'yes') {

      if (defined $$rbrick{save_name}) {
        $$rdata{mode} = 'save_as';
        $$rredirect = sub { $rbrick->save_as($rparent_brick,$rroot_brick,$ra,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
        return;
      }
      else {
        delete $$rdata{mode};

        $rbrick->save();
        return;
      }
    }
    elsif ($$rARGS{submit} eq 'no') {
      delete $$rdata{modified};
      delete $$rdata{mode};
      return;
    }
    else {
      $$rredirect = sub { $rbrick->save_changes_ma($rparent_brick,$rroot_brick,$ra,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
      return;
    }
  }

  if (defined $route_tag) {
    $$rdata{route_tag} = $route_tag;
  }

  if (defined $$ra{fn}) {
    if ($$ra{fn} eq 'edit') {
      $$rredirect = sub { $rbrick->render_props($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
      return;
    }
    elsif ($$ra{fn} eq 'save') {

      $rbrick->super->process($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect);
      return if defined $$rredirect;

      if ($$rbrick{name} ne 'assembly') {
        $rbrick->save();
      }
      else {
        $$rdata{mode} = 'save_as';
        $$rredirect = sub { $rbrick->save_as($rparent_brick,$rroot_brick,$ra,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
      }
    }
    elsif ($$ra{fn} eq 'save_as') {
      $rbrick->super->process($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect);
      return if defined $$rredirect;

      $$rdata{prev_modified_defined} = ($$rdata{modified}) ? 1 : -1;  
      $$rdata{mode} = 'save_as';
      $rbrick->set_modified();
      $$rredirect = sub { $rbrick->save_as($rparent_brick,$rroot_brick,$ra,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
    }
    elsif ($$ra{fn} eq 'close') {

      #
      # get all sub-assemblies
      #

      my @a = $rbrick->find(-1, 'assembly', undef, undef, 'assembly');
      shift @a; # shift off this assembly

      foreach (@a) {
        $_->process($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect);
        return if defined $$rredirect;
      }

      return if ! $$rdata{modified};

      $$rredirect = sub { $rbrick->save_changes_ma($rparent_brick,$rroot_brick,$ra,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
      $$rdata{mode} = 'save_changes_ma';
      return; 
    }
    elsif ($$ra{fn} eq 'process_props') {

      my $rprops = ${$$rbrick{data}}{rprops};

      if (defined $$ra{add_meta}) {

        if (!defined $$rprops{rmetas}) {
          $$rprops{rmetas} = [];
        }

        push @{$$rprops{rmetas}}, $$ra{meta};
        $$rredirect = sub { $rbrick->render_props($rparent_brick,$rroot_brick,$ra,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
        return;
      }
      elsif (defined $$ra{del_meta}) {
        splice (@{$$rprops{rmetas}}, $$ra{del_meta}, 1);
        $$rredirect = sub { $rbrick->render_props($rparent_brick,$rroot_brick,$ra,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect) };
        return;
      }
      else {
        $$rprops{doctype} = $$ra{doctype};
        $$rprops{title} = $$ra{title};
        $$rprops{body} = $$ra{body};
        $$rprops{use_props} = $$ra{use_props};
      }

      $rbrick->set_modified();
    }
  }

  $rbrick->super->process($rparent_brick,$rroot_brick,$rARGS,$rsub_ARGS,$route_tag,$ruri,$mode,$rredirect);
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render
%#----------------------------------------------------------------------------
<%method render>
<%perl>

  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode) = @_;

  my $rdata = $$rbrick{data};

  if (($mode eq 'edit') && ($$rparent_brick{name} eq 'next') && ($$rbrick{name} ne 'authorbar')) {

    my @abars = $$rparent_brick{rparent}->find(1,'assembly','authorbar');

    if (defined shift @abars) {
      $edit_tag = undef;
    }
  }

  my $sub_route_tag = (defined $route_tag) ? "$route_tag.0" : "0";
  my $stag = (defined $edit_tag) ? "$edit_tag.0" : '0';

  my $rprops = ${$$rbrick{data}}{rprops};

  if ((defined $$rprops{doctype}) && ($$rprops{doctype} ne '')) {
    $m->out("<!DOCTYPE $$rprops{doctype}>\n");
  }

  if (!defined $rparent_brick) {

    my %p;

    $rbrick->get_assembly_props(\%p);

    $m->out("<html>\n");
    $m->out("<head>\n");
    $m->out("<title>$p{title}</title>\n");
    foreach (@{$p{rmetas}}) {
      $m->out("<meta $_>\n");
    }

    #
    # I don't ask for money, but I do ask that you don't remove the following tag
    # from your web-site.  This gives me an easy way of finding sites running Bricks
    # by typing bricks_site_builder into a search engine.  I'd love to see what 
    # people are doing with Bricks.  Wouldn't you?
    #

    $m->out("<meta name=\"keywords\" content=\"bricks_site_builder\">\n"); 

    $m->out("</head>\n");
    $m->out("<body" . ((defined $p{body}) ? " $p{body}>\n" : ">\n"));
  }

  if (($mode eq 'edit') && ($$rparent_brick{name} eq 'next')) {
    $m->comp("/editmisc:render_header",
      brick_name => 'assembly',
      brick_notes => ($$rbrick{name} eq 'assembly') ? $$rbrick{save_name} : $$rbrick{name},
      route_tag => $sub_route_tag,
      uri => $uri,
      edit_tag => $stag);
  }

  my $ret = $rbrick->super->render($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode);

  if (!defined $rparent_brick) {
    $m->out("</body>\n");
    $m->out("</html>\n");
  }

  return $ret;
</%perl>
</%method>

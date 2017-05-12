%#----------------------------------------------------------------------------
%# File: table
%#
%# I hereby dedicate this brick to Paul Oakenfold's Tranceport CD, which, 
%# along with lots of tooth and gum destroying Coca-Cola kept me codin'.
%#
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};
  my $rprops = $$rdata{rprops} = {};
  my $nrows = $$rdata{nrows} = 1;
  my $ncols = $$rdata{ncols} = 1;

  my $rcell = $rbrick->new_cell();

  my $rrows = $$rdata{rrows} = [ [ $rcell ] ];

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# delete
%#----------------------------------------------------------------------------
<%method delete>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};

  if (defined $rdata) {
    my $nrows = $$rdata{nrows};
    my $ncols = $$rdata{ncols};

    for (my $i=0; $i < $nrows; $i++) {
      my $rrow = ${$$rdata{rrows}}[$i];

      for (my $j=0; $j < $ncols; $j++) {
        my $rcell = $$rrow[$j];
      
        $rbrick->delete_cell($rcell); 
      }
    }
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# new_cell
%#----------------------------------------------------------------------------
<%method new_cell>
<%perl>
  my ($rbrick) = @_;

  my $rcell = HTML::Bricks::fetch('column');
  $rcell->new();
  my $rdata = $$rcell{data};
  my $rprops = $$rdata{rprops} = {};

  return $rcell;
 
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# delete_cell
%#----------------------------------------------------------------------------
<%method delete_cell>
<%perl>
  my ($rbrick, $rcell) = @_;

  $rcell->delete();

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# get_edit_lists
%#----------------------------------------------------------------------------
<%method get_edit_lists>
<%perl>
  my ($rbrick, $route_tag, $edit_tag, $rpositions, $rdestinations) = @_;

  my $rdata = $$rbrick{data};

  if (defined $rdata) {
    my $nrows = $$rdata{nrows};
    my $ncols = $$rdata{ncols};

    for (my $i=0; $i < $nrows; $i++) {
      my $rrow = ${$$rdata{rrows}}[$i];

      for (my $j=0; $j < $ncols; $j++) {
        my $rcell = $$rrow[$j];
      
        $rcell->get_edit_lists("$route_tag." . ($i * $ncols + $j),"$edit_tag." . ($i * $ncols + $j + 1),
          $rpositions, $rdestinations);
      }
    }
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# set_modified
%#----------------------------------------------------------------------------
<%method set_modified>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};

  $$rbrick{rparent}->set_modified();

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# freeze
%#----------------------------------------------------------------------------
<%method freeze>
<%perl>
  my ($rbrick, $rsub) = @_;

  my %node;
  $node{name} = $$rbrick{name};
  my $rdata = $$rbrick{data};

  my $rnode_data = $node{data} = {};
  my $nrows = $$rnode_data{nrows} = $$rdata{nrows};
  my $ncols = $$rnode_data{ncols} = $$rdata{ncols};

  my $rnode_rrows = $$rnode_data{rrows} = [];

  for (my $i=0; $i < $nrows; $i++) {
    my $rrow = ${$$rdata{rrows}}[$i];

    my $rnode_cells = [];

    for (my $j=0; $j < $ncols; $j++) {
      my $rcell = $$rrow[$j];
      my $rnode_cell;
 
      if (defined $rsub) {
        $rnode_cell = &$rsub($rcell, $rsub);
      } 
      elsif ($rcell->can('freeze')) {
        $rnode_cell = $rcell->freeze();
      }
      else {
        $rnode_cell = {};

        my $VAR1;
        eval(Dumper($$rcell{data}));
        $$rnode_cell{data} = $VAR1;

        $$rnode_cell{name} = $$rcell{name};
      }

      my $rbrick_cell_data = $$rcell{data};
      my $rbrick_cell_props = $$rbrick_cell_data{rprops};

      my $rnode_cell_data = $$rnode_cell{data};
      my $rnode_cell_props = $$rnode_cell_data{rprops} = {};

      if (defined $rbrick_cell_props) {
        %$rnode_cell_props = %$rbrick_cell_props;
      }

      push @$rnode_cells, $rnode_cell;
    }
    push @$rnode_rrows, $rnode_cells;
  }

  my $rnode_props = $$rnode_data{rprops} = {};
  my $rbrick_props = $$rdata{rprops};

  %$rnode_props = %$rbrick_props;

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
  my $rbrick_data = $$rbrick{data} = {};

  my $nrows = $$rbrick_data{nrows} = $$rnode_data{nrows};
  my $ncols = $$rbrick_data{ncols} = $$rnode_data{ncols};

  my $rbrick_rrows = $$rbrick_data{rrows} = [];

  for (my $i=0; $i < $nrows; $i++) {
    my $rrow = ${$$rnode_data{rrows}}[$i];

    my $rbrick_cells = [];

    for (my $j=0; $j < $ncols; $j++) {
      my $rnode = $$rrow[$j];

      my $rcell = HTML::Bricks::fetch($$rnode{name});
      if ($rcell->can('thaw')) {
        $rcell->thaw($rnode);
      }
      else {
        $rcell = {};

        my $VAR1;
        eval(Dumper($$rnode{data}));
        $$rcell = $VAR1;

        $$rcell{name} = $$rnode{name};
      }

      my $rbrick_cell_data = $$rcell{data};
      my $rbrick_cell_props = $$rbrick_cell_data{rprops} = {};

      my $rnode_cell_data = $$rnode{data};
      my $rnode_cell_props = $$rnode_cell_data{rprops};
      if (defined $rnode_cell_props) {
        %$rbrick_cell_props = %$rnode_cell_props;
      }

      $$rcell{rparent} = $rbrick;

      push @$rbrick_cells, $rcell
    }
    push @$rbrick_rrows, $rbrick_cells;
  }

  my $rnode_props = $$rnode_data{rprops};
  my $rbrick_props = $$rbrick_data{rprops} = {};

  %$rbrick_props = %$rnode_props;

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

  if (defined $rdata) {
    my $nrows = $$rdata{nrows};
    my $ncols = $$rdata{ncols};

    for (my $i=0; $i < $nrows; $i++) {
      my $rrow = ${$$rdata{rrows}}[$i];

      for (my $j=0; $j < $ncols; $j++) {
        my $rcell = $$rrow[$j];
        $rcell->walk($walk_comp,$recurse);
      }
    }
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# route_sub
%#
%# See column:route_sub for a description
%#----------------------------------------------------------------------------
<%method route_sub>
<%perl>

  my ($rbrick, $destination, $sub) = @_;

  my $rdata = $$rbrick{data}; 
  my $rcol = $$rdata{rcol};

  if ($destination =~ /(\d*)\.(.*)/) {
    my $row = int($1 / $$rdata{ncols});
    my $col = $1 % $$rdata{ncols};
    my $destination = $2;

    my $rrows = $$rdata{rrows};
    my $rrow = $$rrows[$row];
    my $rcell = $$rrow[$col];

    return $rcell->route_sub($destination,$sub);
  }
  else {
    print STDERR "table:route_sub: destination does not match row.col.rest ($destination)\n";
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render_edit
%#----------------------------------------------------------------------------
<%method render_edit>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};
  my $rprops = $$rdata{rprops};

</%perl>
  <b>table properties</b>
  <p>
  <form method="post" action="<% $$ruri %>">
    <input type="hidden" name="<% $route_tag %>:fn" value="process_brick_edit">
    <table width="1">
%     foreach (@table_props) {
        <tr>
          <td align="right">
            <% $_ %>
          </td>
          <td>
            <input type="text" name="<% "$route_tag:$_" %>" value="<% $$rprops{$_} %>">
          </td>
        </tr>
%     }
    </table>
    <input type="submit" value="update">
    <input type="reset" value="reset">
  </form>
</%method>
 
%#----------------------------------------------------------------------------
%# process_table_edit
%#----------------------------------------------------------------------------
<%method process_table_edit>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};
  my $rprops = $$rdata{rprops};

  foreach (@table_props) {
    my $val = $$rARGS{$_};
   
    if ((defined $val) && ($val ne '')) {
      $$rprops{$_} = $val;
    }
    elsif ($val eq '') { 
      delete $$rprops{$_};
    }
  }

  $rbrick->set_modified();

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render_edit_cell_props
%#----------------------------------------------------------------------------
<%method render_edit_cell_props>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};

  my $props = $$rARGS{edit_cell_props};

  my $row = int($props / $$rdata{ncols});
  my $col = $props % $$rdata{ncols};
 
  my $rrows = $$rdata{rrows};
  my $rrow = @$rrows[$row];
  my $rcell = @$rrow[$col];
  my $rcell_data = $$rcell{data};
  my $rprops = $$rcell_data{rprops};


</%perl>
  <b>cell properties</b>
  <p>
  <form method="post" action="<% $$ruri %>">
    <input type="hidden" name="<% $route_tag %>:fn" value="process_edit_cell_props">
    <input type="hidden" name="<% $route_tag %>:row_col" value="<% $props %>">
    <table width="1">
%     foreach (@cell_props) {
        <tr>
          <td align="right">
            <% $_ %>
          </td>
          <td>
            <input type="text" name="<% "$route_tag:$_" %>" value="<% $$rprops{$_} %>">
          </td>
        </tr>
%     }
    </table>
    <input type="submit" value="update">
    <input type="reset" value="reset">
  </form>
</%method>

%#----------------------------------------------------------------------------
%# process_edit_cell_props
%#----------------------------------------------------------------------------
<%method process_edit_cell_props>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};

  my $props = $$rARGS{row_col};
  my $row = int($props / $$rdata{ncols});
  my $col = $props % $$rdata{ncols};
  
  my $rrows = $$rdata{rrows};
  my $rrow = @$rrows[$row];
  my $rcell = @$rrow[$col];
  my $rcell_data = $$rcell{data};
  my $rprops = $$rcell_data{rprops};

  foreach (@cell_props) {
    my $val = $$rARGS{$_};
   
    if ((defined $val) && ($val ne '')) {
      $$rprops{$_} = $val;
    }
    elsif ($val eq '') { 
      delete $$rprops{$_};
    }
  }

  $rbrick->set_modified();

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};

  my $nrows = $$rdata{nrows};
  my $ncols = $$rdata{ncols};

  for (my $i=0; $i < $nrows; $i++) {
    my $rrow = ${$$rdata{rrows}}[$i];

    for (my $j=0; $j < $ncols; $j++) {
      my $rcell = $$rrow[$j];
      my $rsub_a = $$rsub_ARGS{ $i * $ncols + $j };

      foreach (keys %HTML::Bricks::global_args) {
#        $${$$rsub_a{rARGS}}{$_} = $HTML::Bricks::global_args{$_};
      }

      $$rcell{rparent} = $rbrick;
      $rcell->process($rbrick, $rroot_brick, $$rsub_a{rARGS}, $$rsub_a{rsub_ARGS},
          "$route_tag." . ($i * $$rdata{ncols} + $j), $ruri, $mode, $rredirect);
    }
  }

  if ($mode eq 'edit') {
    my $split_row = $$rARGS{split_row};
    my $split_col = $$rARGS{split_col};    
    my $unsplit_row = $$rARGS{unsplit_row};
    my $unsplit_col = $$rARGS{unsplit_col};
    my $props = $$rARGS{props};
    my $set_props = $$rARGS{set_props};

    if ($$rARGS{fn} eq 'edit') {
      $$rredirect = sub { $rbrick->render_edit($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) };
    }
    elsif ($$rARGS{fn} eq 'process_brick_edit') {
      $rbrick->process_table_edit($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect);
    }
    elsif (defined $$rARGS{'edit_cell_props'}) {
      $$rredirect = sub { $rbrick->render_edit_cell_props($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect); };
    }
    elsif ($$rARGS{fn} eq 'process_edit_cell_props') {
      $rbrick->process_edit_cell_props($rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect);
    }
    elsif (defined $split_row) { 
   
      my @col; 
      for (my $i=0; $i < $$rdata{ncols}; $i++) {
        my $rcell = $rbrick->new_cell();
        push @col, $rcell;
      }

      my $rary = $$rdata{rrows};

      splice(@$rary, $split_row, 0, \@col); 

      $$rdata{nrows} += 1;

      $rbrick->set_modified();
    } 
    elsif (defined $split_col) {

      my $rrows = $$rdata{rrows};
      foreach (@$rrows) {
        my $rcell = $rbrick->new_cell();
        splice(@$_, $split_col, 0, $rcell);
      }

      $$rdata{ncols} += 1;

      $rbrick->set_modified();
    }
    elsif (defined $unsplit_row) {
      $unsplit_row =~ /(\d)\.(.*)/;
      my $row = $1;
      my $dir = $2;

      my $rrows = $$rdata{rrows};
      my $rrow = $$rrows[$row];

      my $insrow = ($dir eq 'up') ? $row - 1 : $row + 1;
      my $rinsrow = $$rrows[$insrow];

# bad abstraction here: a table brick is modifying two column bricks based on 
# knowledge of the column brick's implementation.  Fix this.

      for (my $i=0; $i <= $#$rrow; $i++) {
        my $rsrc_cell = $$rrow[$i];  
        my $rdst_cell = $$rinsrow[$i];

        my $rsrc_col = ${$$rsrc_cell{data}}{rcol};
        my $rdst_col = ${$$rdst_cell{data}}{rcol};

        if ($dir eq 'up') {
          while (my $rsrc_brick = shift @$rsrc_col) {
            push @$rdst_col, $rsrc_brick
          } 
        } 
        else {
          while (my $rsrc_brick = pop @$rsrc_col) {
            unshift @$rdst_col, $rsrc_brick
          }
        }
      }

      splice(@$rrows, $row, 1);

      $$rdata{nrows} -= 1;

      $rbrick->set_modified();
    }
    elsif (defined $unsplit_col) {
      $unsplit_col =~ /(\d)\.(.*)/;
      my $src_col = $1;
      my $dir = $2;
      my $dst_col = ($dir eq 'left') ? $src_col - 1 : $src_col + 1;
      
      my $rrows = $$rdata{rrows};
        
      foreach my $rrow (@$rrows) {
        my $rsrc_cell = @$rrow[$src_col];
        my $rdst_cell = @$rrow[$dst_col];
        
        my $rsrc_col = ${$$rsrc_cell{data}}{rcol};
        my $rdst_col = ${$$rdst_cell{data}}{rcol};
 
        if ($dir eq 'left') {
          while (my $rsrc_brick = shift @$rsrc_col) {
            push @$rdst_col, $rsrc_brick
          }
        }
        else {
          while (my $rsrc_brick = pop @$rsrc_col) {
            unshift @$rdst_col, $rsrc_brick
          }
        }

        splice(@$rrow, $src_col, 1);
      }

      $$rdata{ncols} -= 1;

      $rbrick->set_modified();
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
  my $rprops = $$rdata{rprops};

  #
  # render the <table> tag in all its' glory
  #

  my $table_props;
  my $ed_table_props;

  foreach (keys %$rprops) {
    $table_props .= " $_=\"$$rprops{$_}\"";

    next if $_ eq 'border';
    next if $_ eq 'cellspacing';
    next if $_ eq 'cellpadding';
 
    $ed_table_props .= " $_=\"$$rprops{$_}\"";
  }    

  if ($mode eq 'edit') {
    $m->out("<table" . $ed_table_props . " cellspacing=\"0\" cellpadding=\"0\" frame=\"border\" border=\"1\">\n");
    $m->out("  <tr>\n");
    $m->out("    <td>\n");
  }

  $m->out("<table" . $table_props . ">\n");

  #
  # set up the row-col loop
  #

  my $nrows = $$rdata{nrows};
  my $ncols = $$rdata{ncols};

  my $start_r = 0;
  my $start_c = 0;

  if ($mode eq 'edit') {
    $start_r--;
    $start_c--;
  }
     
  #
  # loop through the rows and columns
  #

  for (my $r = $start_r; $r < $nrows; $r++) {
    my $spanning = 0;

    if ($r == -1) {
      $m->out("  <tr height=\"1\">\n");
    }
    else {
      $m->out("  <tr>\n");
    }

    for (my $c = $start_c; $c < $ncols; $c++) {

      if ($r == -1) {   
        if ($c == -1) {
          $m->out("    <td width=\"1\">\n");
          $m->out("    </td>\n");
        } 
        else {
          my $href;

          $m->out("    <td>\n");
          $m->out("      <table width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\">\n");
          $m->out("        <tr>\n");

          if ($c != 0) {
            $m->out("          <td align=\"left\" valign=\"bottom\">\n");
            $href = "$uri$route_tag:unsplit_col=$c.left";
            $m->out("      <a href=\"$href\"><img border=\"0\" src=\"/bricks_images/unsplit_left.gif\"></a>&nbsp;\n");
            $m->out("          </td>\n");
          }

          $m->out("          <td align=\"center\">\n");
          $href = "$uri$route_tag:split_col=$c";
          $m->out("<a href=\"$href\">split</a>&nbsp;\n");
          $m->out("          </td>\n");

          if ($c != $ncols-1) {
            $m->out("          <td valign=\"bottom\" align=\"right\">\n");
            $href = "$uri$route_tag:unsplit_col=$c.right";
            $m->out("<a href=\"$href\"><img border=\"0\" src=\"/bricks_images/unsplit_right.gif\"></a>\n");
            $m->out("          </td>\n");
          }
          else {
            $m->out("          <td valign=\"bottom\" align=\"right\">\n");
            $href = "$uri$route_tag:split_col=" . ($c+1);
            $m->out("<a href=\"$href\">+</a>&nbsp;");
            $m->out("          </td>\n");
          }
          $m->out("        </tr>\n");
          $m->out("      </table>\n");
          $m->out("    </td>\n");
        } 
      }
      else {
        # normal row
        if ($c == -1) {
          my $href = "$uri$route_tag:add_row=$r";
 
          $m->out("    <td width=\"1\">\n");
          $m->out("      <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\">\n");
 

          $m->out("        <tr>\n");
          $m->out("          <td valign=\"top\" align=\"right\">\n");

          if ($r != 0) { 
            $href = "$uri$route_tag:unsplit_row=$r.up";
            $m->out("            <a href=\"$href\"><img border=\"0\" src=\"/bricks_images/unsplit_up.gif\"></a>\n");
          }
          else {
            $m->out("\n");
          }

          $m->out("          </td>\n");
          $m->out("        </tr>\n");

          $href = "$uri$route_tag:split_row=$r";
          $m->out("        <tr>\n");
          $m->out("          <td valign=\"center\">\n");
          $m->out("            <a href=\"$href\">split</a>\n");
          $m->out("          </td>\n");
          $m->out("        </tr>\n");

          $m->out("        <tr>\n");
          $m->out("          <td valign=\"bottom\" align=\"right\">\n");

          if ($r != $nrows-1) {
            $href = "$uri$route_tag:unsplit_row=$r.down";
            $m->out("            <a href=\"$href\"><img border=0 src=\"/bricks_images/unsplit_down.gif\"></a>\n");
          } 
          else {
            $href = "$uri$route_tag:split_row=" . ($r+1);
            $m->out("            <a href=\"$href\">+</a>\n");
          }

          $m->out("          </td>\n");
#          $m->out("        </tr>\n");

          $m->out("        </tr>\n");
          $m->out("      </table>\n");
          $m->out("    </td>\n");
        }
        else {

          #
          # Render a cell
          #

          my $cell_num = $r * $$rdata{ncols} + $c;

          my $rrows = $$rdata{rrows};
          my $rrow = @$rrows[$r];
          my $rcell = @$rrow[$c];
          my $rcell_data = $$rcell{data};
          my $rprops = $$rcell_data{rprops};

          if ($spanning) {
            $spanning--;
            next;
          }
          if ($$rprops{colspan}) {
            $spanning = $$rprops{colspan} - 1;
          }

          my $td_props;
          if (defined $rprops) {
            foreach (keys %$rprops) {
              if (($_ eq 'colspan') && ($mode eq 'edit')) {
                next;
              }
              $td_props .= " $_=\"$$rprops{$_}\"";
            }
          }

          if ($mode eq 'edit') {
            if ($spanning) {
              $m->out("    <td valign=\"top\" colspan=\"$$rprops{colspan}\"" . $td_props .">\n");
            }
            else {
              $m->out("    <td valign=\"top\"" . $td_props . ">\n");
            }

            $m->comp("/editmisc:render_header",
              brick_name => 'cell',
              fn => 'edit_cell_props=' . ($r * $$rdata{ncols} + $c),
              route_tag => $route_tag,
              uri => $uri,
              edit_tag => "$edit_tag." . ($r * $ncols + $c + 1));

          }
          else {
            $m->out("          <td" . $td_props .">\n");
          }
          
          my $rsub_a = $$rsub_ARGS{ $r * $$rdata{ncols} + $c};  

          foreach (keys %HTML::Bricks::global_args) {
#            $${$$rsub_a{rARGS}}{$_} = $HTML::Bricks::global_args{$_};
          }

          $rcell->render($rbrick,$rroot_brick, 
              $$rsub_a{rARGS}, $$rsub_a{rsub_ARGS},
              "$route_tag." . ($r * $ncols + $c),
              "$edit_tag." . ($r * $ncols + $c + 1), $uri, $mode);

          $m->out("\n");
          $m->out("        </td>\n");

          if ($mode eq 'edit') {
#             $m->out("      </tr>\n");
#             $m->out("    </table>\n");
#            $m->out("  </td>\n");
          }
        }
      }
    } 
    $m->out("  </tr>\n");
  }
  $m->out("</table>\n"); 

  if ($mode eq 'edit') {
    $m->out("    </td>\n");
    $m->out("  </tr>\n");
    $m->out("</table>\n"); 
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
<%once>

  my @table_props = ('width','height','border','cellspacing','cellpadding','bgcolor','class');
  my @cell_props = ('width','height','align','valign','bgcolor','color','colspan','class');

</%once>

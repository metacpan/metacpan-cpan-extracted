%#----------------------------------------------------------------------------
%# File: column
%#
%# This is the fundamental brick: the column, a container of other bricks
%# which are rendered in list order
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};
  my $rcol = $$rdata{rcol} = [];

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# delete
%#----------------------------------------------------------------------------
<%method delete>
<%perl>
  my ($rbrick) = @_;

  my $rdata = $$rbrick{data};
  my $rcol = $$rdata{rcol};
  
  foreach (@$rcol) {
    use HTML::Bricks;

    if ($_->can('delete')) {
      $_->delete();
    }
  }

  delete $$rbrick{data};
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
%# get_edit_lists
%#----------------------------------------------------------------------------
<%method get_edit_lists>
<%perl>
  my ($rbrick, $route_tag, $edit_tag, $rpositions, $rdestinations) = @_;

  my $rdata = $$rbrick{data};

  my $rtag = (defined $route_tag) ? "$route_tag." : "$route_tag";
  my $etag = (defined $edit_tag) ? "$edit_tag." : "$edit_tag";

  if (defined $rdata) {
    my $rcol = $$rdata{rcol};

    my $i=1; 
    foreach (@$rcol) {
      my $name;

      my $stag = (defined $edit_tag) ? "$edit_tag.$i" : $i;

      if ($_->can('get_label')) {
        $name = $_->get_label;
      }
      else {
        $name = $$_{name};
      }

      push @$rpositions, ["$rtag$i", "$stag $name"];
      push @$rdestinations, ["$rtag$i", "$stag $name"];

      if ($_->can('get_edit_lists')) {
        $_->get_edit_lists("$rtag$i",$stag,$rpositions,$rdestinations);
      }

      $i++;
    } 
    
    if ($#$rcol != -1) {
      if ($edit_tag ne '') {
        push @$rdestinations, ["$rtag$i", "$edit_tag.$i bottom"];
      }
      else {
        push @$rdestinations, ["$rtag$i", "$i bottom"];
      }
    }
    else {
      if ($edit_tag ne '') {
        push @$rdestinations, ["$rtag" . "1", "$edit_tag.0 top"];
      }
      else {
        push @$rdestinations, ["$rtag" . "1", "top"];
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

  $$rbrick{rparent}->set_modified();

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# freeze
%#----------------------------------------------------------------------------
<%method freeze>
<%perl>
  my ($rbrick, $rsub) = @_;

  use Data::Dumper;
  
  my %node;
  $node{name} = $$rbrick{name};
  my $rnode_data = $node{data} = {};
  $$rnode_data{rcol} = [];

  my $rdata = $$rbrick{data};
  my $rcol = $$rdata{rcol};

  foreach (@$rcol) {
    my $rsub_node;

    if (defined $rsub) { 
      $rsub_node = &$rsub($_, $rsub);
    }
    elsif ($_->can('freeze')) {
      $rsub_node = $_->freeze($rsub);
    }
    else {
      $rsub_node = {};

      my $VAR1;
      eval(Dumper($$_{data}));
      $$rsub_node{data} = $VAR1;
      $$rsub_node{name} = $$_{name};
    }

    push @{$$rnode_data{rcol}}, $rsub_node;
  }

  return \%node;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# thaw
%#----------------------------------------------------------------------------
<%method thaw>
<%perl>
  my ($rbrick, $rnode) = @_;

  my $rbrick_data = $$rbrick{data}; 
  my $rbrick_rcol = $$rbrick_data{rcol} = [];

  my $rnode_data = $$rnode{data};
  my $rcol = $$rnode_data{rcol};

  foreach (@$rcol) {

    my $rsub_brick = HTML::Bricks::fetch($$_{name});
    if (defined $rsub_brick) {
      if ($rsub_brick->can('thaw')) {
        $rsub_brick->thaw($_);
      }
      else {
        my $VAR1;
        eval(Dumper($$_{data}));

        %{$$rsub_brick{data}} = %$VAR1 if defined $VAR1;

        $$rsub_brick{name} = $$_{name};
        bless $rsub_brick, "HTML::Bricks::Brick_mason";
      }
    }
    else {
      # 
      # couldn't find the brick, so create an 'unknown' brick to store the data
      #
 
      $rsub_brick = HTML::Bricks::fetch('unknown');

      if (!defined $rsub_brick) {
        die "column:thaw: could not find 'unknown' brick, you probably have a configuration error.";
      }

      $rsub_brick = $rsub_brick->thaw($_);
    }
    $$rsub_brick{rparent} = $rbrick;

    push @$rbrick_rcol, $rsub_brick;
  }

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
  my $rcol = $$rdata{rcol};

  foreach (@$rcol) { 
    return if ! &$walk_comp($_);
    if (($recurse) && ($_->can('walk'))) {
      $_->walk($walk_comp,$recurse);
    }
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# route_sub($destination, $sub)
%#
%# $destination        location of destinaton brick (e.g. 1.2.13.1)
%# $sub                callback subroutine
%#
%# Routes a subroutine call to a specific brick.  The subroutine is called
%# as follows:
%#
%#   &$sub($rtarget_brick, $rparent_brick, $rcolumn_array, $column_index)
%#
%# $rtarget_brick      the actual brick that this subroutine is routed to
%# $rparent_brick      the parent of the target brick, this column
%# $rcolumn_array      a reference to the array containing this brick
%# $column_index       the index of this column in the array
%#
%# The subroutine itself can be a closure.  If you aren't familiar with 
%# closures, check the perlref manpage.  Closures are one of Perl's most 
%# powerful features.  See editactions.mc for examples.
%#----------------------------------------------------------------------------
<%method route_sub>
<%perl>

  my ($rbrick, $destination, $sub) = @_;

  my $rdata = $$rbrick{data}; 
  my $rcol = $$rdata{rcol};

  if ($destination !~ /(\d*)\.(.*)/) {
    return &$sub($$rcol[$destination - 1], $rbrick, $rcol, $destination);
  } 
  else {
    my $sub_destination = $2;
    my $rsub_brick = ${$$rdata{rcol}}[$1 - 1];

    if ($rsub_brick->can('route_sub')) {
      $rsub_brick->route_sub($sub_destination, $sub);
    }
    else {
      print STDERR "column:route_sub: $$rsub_brick{name} doesn't have method 'route_sub'\n"; 
    }
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# check_match
%#
%# used in find below
%#----------------------------------------------------------------------------
<%method check_match>
<%perl>
  my ($rbrick, $rcurrent_brick, $rcount, $name_match, $id_match, $type_match, $rmatches) = @_;

#  print STDERR "check_match: $$rcurrent_brick{name} $$rcount matches $name_match $id_match $type_match?\n";

  if (($$rcurrent_brick{name} =~ $name_match) && ($$rcurrent_brick{id} =~ $id_match)) {

    if ($type_match eq 'assembly') {

      if (! $rcurrent_brick->can('is_assembly')) {

        if (! $rcurrent_brick->can('get_next')) {
          return 1; 
        }
        else {
          $rcurrent_brick = $rcurrent_brick->get_next();
          return 1 if !defined $rcurrent_brick;
        }
      }
    }

    push @$rmatches, $rcurrent_brick;
    return undef if --$$rcount == 0;
  }

  return 1;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# find
%#
%# search_type = 'global', 'assembly', 'this_column', 'this_column_norecurse'
%# name_match  = perl regexp to match name by
%# id_match    = perl regexp to match id by
%#----------------------------------------------------------------------------
<%method find>
<%perl>
  my ($rbrick, $count, $search_type, $name_match, $id_match, $type_match) = @_;

#  print STDERR "column:find count=$count search_type=$search_type name_match=$name_match id_match=$id_match type_match=$type_match\n";

  $count = -1 if !defined $count;
  $search_type = 'global' if !defined $search_type;
  $name_match = '.*' if !defined $name_match;
  $id_match = '.*' if !defined $id_match;
  $type_match = '.*' if !defined $type_match;

  my @matches;

  my $rdata = $$rbrick{data}; 
  my $rcol = $$rdata{rcol};

  #
  # find a starting brick
  #

  my $rstart_brick = $rbrick;

  if ($search_type eq 'global') {
    while ($$rstart_brick{rparent}) {
      $rstart_brick = $$rstart_brick{rparent};
    }
  } 
  elsif ($search_type eq 'assembly') {
    while (! $rstart_brick->can('is_assembly')) {
      $rstart_brick = $$rstart_brick{rparent};
    }
  }

  my $recurse = ($search_type eq 'this_column_norecurse') ? 0  : 1;

  my $check = sub { return $rbrick->check_match(shift,\$count,$name_match,$id_match,$type_match,\@matches);};

  return @matches if ! &$check($rstart_brick);
  $rstart_brick->walk($check, $recurse);

  return @matches;

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};
  my $rcol = $$rdata{rcol};

  my $i=1;
  foreach (@$rcol) { 

    my $ra = $$rsub_ARGS{$i};  
    my $rsub_a = $$ra{rARGS};
    my $rsub_sub_a = $$ra{rsub_ARGS};

    if ($_->can('process')) {

      foreach (keys %HTML::Bricks::global_args) {
        $$rsub_a{$_} = $HTML::Bricks::global_args{$_};
      }

      $$_{rparent} = $rbrick;

      $_->process($rbrick,$rroot_brick,$rsub_a,$rsub_sub_a,
          (defined $route_tag) ? "$route_tag.$i" : $i,
          $ruri,$mode,$rredirect);
    }
    $i++;
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
  my $rcol = $$rdata{rcol};
  
  if (!defined $rcol) {
    my @ary;
    $rcol = \@ary;
  }

  my $i=1;
  foreach (@$rcol) {

    my $ra = $$rsub_ARGS{$i};  
    my $rsub_a = $$ra{rARGS};
    my $rsub_sub_a = $$ra{rsub_ARGS};

    my $sub_route_tag = (defined $route_tag) ? "$route_tag.$i" : $i;
    my $stag = (defined $edit_tag) ? "$edit_tag.$i" : $i;

    if ($mode eq 'edit') {

      my $brick_label;
      my $brick_notes;

      if ($_->can('get_label')) {
        ($brick_label,$brick_notes) = $_->get_label();
      }
      else {
        $brick_label = $$_{name};
      }

      $m->comp("/editmisc:render_header",
        brick_name => $brick_label,
        brick_notes => $brick_notes,
        route_tag => $sub_route_tag,
        uri => $uri,
        edit_tag => $stag);
    }

    foreach (keys %HTML::Bricks::global_args) {
      $$rsub_a{$_} = $HTML::Bricks::global_args{$_};
    }

    if ($_->can('render')) {
      $_->render($rbrick,$rroot_brick,$rsub_a,$rsub_sub_a,$sub_route_tag,$stag,$uri,$mode);
    }

    $i++;
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# File: editactions
%#----------------------------------------------------------------------------

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
  my ($rbrick) = @_;

  return { name => $$rbrick{name} };

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# thaw
%#----------------------------------------------------------------------------
<%method thaw>
<%perl>
  my ($rbrick, $rnode) = @_;

  return { name => $$rnode{name} };

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  if ((defined $$rARGS{op}) && ($HTML::Bricks::session{mode} eq 'edit')) {

    my @a = $rparent_brick->find(1,'assembly', undef, undef, 'assembly');
    my $rassembly = shift @a;
    my $rnext_brick = $rassembly->get_next();
    
    my $op = $$rARGS{op};
    my $brick_name = $$rARGS{type};
    my $destination = $$rARGS{destination};
    my $source = $$rARGS{source};

    if ($op eq 'move') {

      return if $destination eq '';
      return if $source eq '';

      $rnext_brick->route_sub($source,
        sub {
          my ($rtarget_brick, $rparent_brick, $rcol, $i) = @_;

          # insert the brick
 
          $rnext_brick->route_sub($destination,
            sub {
              my ($rignored_brick, $rparent_brick, $rcol, $i) = @_;

              splice (@$rcol, $i - 1, 0, $rtarget_brick);
              $$rtarget_brick{rparent} = $rparent_brick;

              my @found = $rparent_brick->find(1,'assembly');
              my $rpage_brick = shift @found;
              $rpage_brick->set_id($rtarget_brick);

              $rparent_brick->set_modified();
            });

          # if the brick was inserted before this brick (and in the same
          # array), then the position the brick originally took was bumped
          # down one.  Check for that case and correct as needed.

          if (${$$rcol[$i - 1]}{id} ne $$rtarget_brick{id}) {
            $i++;
          }
   
          splice(@$rcol, $i - 1, 1);
          $rparent_brick->set_modified();
        });

    }
    elsif ($op eq 'copy') {
      return if $destination eq '';
      return if $source eq '';

      #
      # get the source brick, clone it, then insert it
      #

      $rnext_brick->route_sub($source,
        sub {
          my ($rtarget_brick, $rparent_brick, $rcol, $i) = @_;

          # clone the brick

          my $rclone;

          if ($rtarget_brick->can('freeze')) {
            my $rfrozen = $rtarget_brick->freeze();
            $rclone = HTML::Bricks::fetch($$rfrozen{name});
            $rclone->thaw($rfrozen)
          }
          else {
            $rclone = HTML::Bricks::fetch($$rtarget_brick{name});
 
            $rclone->new() if $rclone->can('new');
     
            my $VAR1;
            eval(Dumper($$rtarget_brick{data}));
            $$rclone{data} = $VAR1;
          }

          # insert the brick
 
          $rnext_brick->route_sub($destination,
            sub {
              my ($rignored_brick, $rparent_brick, $rcol, $i) = @_;

              splice (@$rcol, $i - 1, 0, $rclone);
              $$rclone{rparent} = $rparent_brick;

              my @found = $rparent_brick->find(1,'assembly');
              my $rpage_brick = shift @found;
              $rpage_brick->set_id($rclone);

              $rparent_brick->set_modified();
            });
        });
    }
    elsif ($op eq 'ins') {
      return if $destination eq '';
      return if $brick_name eq '';

      my $rbrick_to_insert = HTML::Bricks::fetch($brick_name);

      if ($rbrick_to_insert->can('new')) {
        $rbrick_to_insert->new();
      }

      $$rbrick_to_insert{id} = $$rroot_brick{next_brick_id}++;

      $rnext_brick->route_sub($destination,
        sub { 
          my ($rtarget_brick, $rparent_brick, $rcol, $i) = @_;

          splice (@$rcol, $i - 1, 0, $rbrick_to_insert);
          $$rbrick_to_insert{rparent} = $rparent_brick;

          my @found = $rparent_brick->find(1,'assembly');
          my $rpage_brick = shift @found;
          $rpage_brick->set_id($rbrick_to_insert);

          $rparent_brick->set_modified();
        });

    }
    elsif ($op eq 'del') {
      $source = $destination if $source eq '';
      return if $source eq '';

      my $rremoved_brick;

      $rnext_brick->route_sub($source,
        sub {
          my ($rtarget_brick, $rparent_brick, $rcol, $i) = @_;

          $rparent_brick->set_modified();
          $rremoved_brick = splice(@$rcol, $i - 1, 1);
        });
      if ($rremoved_brick->can('is_assembly')) {
        push @HTML::Bricks::discarded_rassemblies, $rremoved_brick->freeze();
      }
      elsif ($rremoved_brick->can('delete')) {
        $rremoved_brick->delete($rremoved_brick);
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
  return undef unless $HTML::Bricks::session{mode} eq 'edit';

  my @a = $rparent_brick->find(1,'assembly', undef, undef, 'assembly');
  my $rassembly = shift @a;
  my $rnext_brick = $rassembly->get_next(); 
  return if !defined $rnext_brick;

  #
  # create the position and move lists for moving bricks
  #

  my @positions;
  my @destinations;

  $rnext_brick->get_edit_lists(undef,undef,\@positions,\@destinations);

  my $rbricks = HTML::Bricks::get_bricks_list();
  my @sorted_bricks = sort { $a cmp $b } @$rbricks; 

</%perl>
  <form method="post" action="<% $uri %>">
    <table width="1" height="1" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td>
          <select name="<% $route_tag %>:op">
            <option value="">- op -
            <option value="ins">ins
            <option value="move">move
            <option value="copy">copy
            <option value="del">del
          </select>
        </td>
        <td>
          <select name="<% $route_tag %>:type">
            <option value="">- type -
%           foreach (@sorted_bricks) {
              <option value="<% $_ %>"><% $_ %>
%           }
          </select>
        </td>
        <td>
          <select name="<% $route_tag %>:source">
            <option value="">- source -
%           foreach (@positions) {
              <option value="<% $$_[0] %>"><% $$_[1] %>
%           }
          </select>
        </td>
        <td>
          <select name="<% $route_tag %>:destination">
            <option value="">- destination -
%           foreach (@destinations) {
              <option value="<% $$_[0] %>"><% $$_[1] %>
%           }
          </select>
        </td>
        <td>
          <input type="submit" value="go">
        </td>
      </tr>
    </table>
  </form> 
</%method>

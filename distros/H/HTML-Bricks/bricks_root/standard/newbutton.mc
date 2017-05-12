%#----------------------------------------------------------------------------
%# File: newbutton
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
%# render_edit
%#----------------------------------------------------------------------------
<%method render_edit>

This button displays a link labeled 'new' which will create a new assembly
to be edited. 

</%method>
 
%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  if ($$rARGS{fn} eq 'new') {

    my $first = 1;
    foreach (@$HTML::Bricks::rmatches) {
      next if $first++ == 1;
      push @HTML::Bricks::discarded_rassemblies, $_->freeze();
    }

    my $rassy = HTML::Bricks::fetch('assembly');
    $rassy->new();
    $rassy->set_modified();

    my @a = $rparent_brick->find(1,'assembly',undef,undef,'assembly');
    my $rassembly = shift @a;
    $rassembly->set_next($rassy);
    $$HTML::Bricks::rmatches[1] = $rassy;
  }

</%perl>
</%method>

%#----------------------------------------------------------------------------
%# render
%#----------------------------------------------------------------------------
<%method render>
% my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri) = @_;
    <a class="authorbar" href="/new_brick.html?<% $route_tag %>:fn=new">new</a>
</%method>

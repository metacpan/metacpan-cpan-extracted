%#---------------------------------------------------------------------
%# File: open
%#
%# list assemblies that can be opened with links to open them
%#---------------------------------------------------------------------

%#---------------------------------------------------------------------
%# render
%#---------------------------------------------------------------------
<%method render>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $edit_tag, $uri, $mode) = @_;

  use Apache::Util qw(escape_uri);

  my $rbricks = HTML::Bricks::get_assemblies_list(); 

  if (!defined $HTML::Bricks::session{username}) {
    $m->out('<b>access denied</b>');
    return;
  }

  my @sorted_bricks = sort { $a cmp $b } @$rbricks;

</%perl>
<b>open assembly</b>
<p>
%  foreach (@sorted_bricks) {
%    next if $_ eq 'assembly';
     <a href="/?g:bricks_edit_assy=<% escape_uri($_) %>"><% $_ %></a><br>
%  }
</%method>

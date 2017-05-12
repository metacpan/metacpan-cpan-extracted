%#----------------------------------------------------------------------------
%# File: assyslist
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
  my $rdata = $$rbrick{data};

  my %node;
  my $rnode_data = $node{data} = {};

  $node{name} = $$rbrick{name};

  $$rnode_data{current} = $$rdata{current};

  return \%node;
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# thaw
%#----------------------------------------------------------------------------
<%method thaw>
<%perl>
  my ($rbrick, $rnode) = @_;

  my $rnode_data = $$rnode{data};
  my $rdata = $$rbrick{data};

  $$rdata{current} = $$rnode_data{current};

  return $rbrick;
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# walk
%#
%# TODO: RETHINK THIS!!!
%#----------------------------------------------------------------------------
<%method walk2>
<%perl>
  my ($rbrick, $walk_comp, $rARGS, $recurse) = @_;

  my $rdata = $$rbrick{data};

  if (defined $$rdata{rfull_matches}) {
    for (my $i=0; $i < $#{$$rdata{rfull_matches}}; $i++) {
      if ($i == $$rdata{current}) {
        next;
      }

      my $rmatches = $$rdata{rfull_matches};
      my $rmatch = $$rmatches[$i];

      my $ra = \%ARGS;
      $$ra{rcurrent_brick} = $rmatch;
      &$walk_comp($rARGS);

      if ($recurse) {
        my $rb = HTML::Bricks::fetch($$rmatch{name});
        if ($rb->can('walk')) {
          $rb->walk($walk_comp,$rARGS);
        }
      }
    }
  }
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# process
%#----------------------------------------------------------------------------
<%method process>
<%perl>
  my ($rbrick, $rparent_brick, $rroot_brick, $rARGS, $rsub_ARGS, $route_tag, $ruri, $mode, $rredirect) = @_;

  my $rdata = $$rbrick{data};

  my @a = $rparent_brick->find(1,'assembly',undef,undef,'assembly');
  my $rassembly = shift @a;

  my $rnext = $rassembly->get_next();
  return if !defined $rnext;

  my @assemblies = ( $rnext );

  $rnext->walk(sub { my $rcurrent = shift; push @assemblies, $rcurrent if $rcurrent->can('is_assembly'); return 1 }, 1);

  $$rdata{rassemblies_list} = \@assemblies;

  if (defined $$rARGS{all}) {
    delete $$rdata{current};
  }
  elsif (defined $$rARGS{n}) {
    $$rdata{current} = $$rARGS{n};
  }

  if (defined $$rdata{current}) {
    $rassembly->set_next($assemblies[$$rdata{current}]);
    $assemblies[$$rdata{current}]->set_next(undef);
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

  my $rassemblies = $$rdata{rassemblies_list};

  return if $#$rassemblies == -1;

  $m->out("<span class=\"authorbar\">[</span>");

  if (($#$rassemblies == 0) && (!defined $$rdata{current})) {
    $m->out(${$$rassemblies[0]}{name});
  }
  else {
    my $rmatch_array;

    if (defined $$rdata{current}) {
      $m->out("<a class=\"authorbar\" href=\"$uri$route_tag:all=1\">all</a>");
    }
    else {
      $m->out("<span class=\"authorbar\">all</a>");
    }
  
    for (my $i=0; $i <= $#$rassemblies; $i++) {
 
      my $rmatch = $$rassemblies[$i];
  
      $m->out(",");
 
      if ((defined $$rdata{current}) && ($i eq $$rdata{current})) { 
        $m->out("&nbsp;$$rmatch{name}");
      }
      else {
        $m->out("&nbsp;<a class=\"authorbar\" href=\"$uri$route_tag:n=$i\">$$rmatch{name}</a>");
      }

    }
  }

  $m->out("<span class=\"authorbar\">]</span>\n");

</%perl>
</%method>

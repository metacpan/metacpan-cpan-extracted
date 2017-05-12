#

package HTML::WebMake::SiteMap;


use Carp;
use strict;
use HTML::WebMake::Main;

use vars	qw{
  	@ISA $ROOTNAME
};




###########################################################################

$ROOTNAME		= "{ROOT}";

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main) = @_;

  my $self = {
    'main'		=> $main,
    'default_score'	=> 50,
    'root_content'	=> undef,
    'set_navlinks'	=> 0,
  };

  bless ($self, $class);
  $self;
}

sub dbg { HTML::WebMake::Main::dbg (@_); }
sub dbg2 { HTML::WebMake::Main::dbg2 (@_); }

# -------------------------------------------------------------------------

sub set_default_score {
  my ($self, $score) = @_;
  $self->{default_score} = $score;
}

sub set_root {
  my ($self, $contobj) = @_;

  if (defined $self->{root_content} && $self->{root_content} != $contobj)
  {
    warn "multiple root <content> items defined: ".
    	$self->{root_content}->as_string()." vs. ".
	$contobj->as_string()."\n";
    return;
  }

  dbg ("set root content item: \${".$contobj->{name}."}");
  $self->{root_content} = $contobj;
}

sub get_root {
  my ($self) = @_;

  $self->{root_content};
}

# -------------------------------------------------------------------------

sub create_up_links {
  my ($self) = @_;

  # only do this once
  if ($self->{created_up_links}) { return; }
  $self->{created_up_links} = 1;

  foreach my $contobj (values %{$self->{main}->{contents}},
  			values %{$self->{main}->{metadatas}})
  {
    if (!defined $contobj) {
      warn "map_site: content object not defined\n";
      next;
    }

    next if ($contobj->{no_map});
    # no magic variables or this.foo metadata please.
    next if ($contobj->{name} =~ /^(?:|WebMake|this)\./);

    my $upobj = $contobj->get_up_content();
    if (!defined $upobj) { $upobj = $self->{root_content}; }
    if (!defined $upobj) { next; }

    dbg ("mapping site: $contobj->{name}: up=$upobj->{name}");

    $upobj->add_kid ($contobj);
  }
}

# -------------------------------------------------------------------------

sub map_site {
  my ($self, $top, $map_generated_content, $contname) = @_;
  my $output;

  return "" if ($self->{mapping_now});

  my $contobj = $self->{main}->get_content_obj ($contname);
  die "map_site: no content object defined for $contname"
  				if (!defined $contobj);

  $self->{mapping_now} = 1;	# avoid re-entrance
  {
    $self->create_up_links();
    if (!defined $top) {
      $top = $self->{root_content};
    } else {
      # from now on, this is the default root for breadcrumbs etc.
      $self->set_root ($top);
    }

    # can't make a sitemap from the root if no root content is defined!
    if (!defined $top) {
      $self->{main}->fail ("sitemap: no root <content> item was defined!");
      goto failure;
    }

    my $context = {
      'top'			=> $top,
      'include_generated'	=> $map_generated_content,
      'sortby'			=> $contobj->{sortorder},
      'node'			=> $contobj->{sitemap_node_name},
      'leaf'			=> $contobj->{sitemap_leaf_name},
      'dynamic'			=> $contobj->{sitemap_dynamic_name},
      'up'			=> undef,
      'prev'			=> undef,
    };


    if (!defined $context->{node}) {
      $self->{main}->fail
      		("sitemap: node content not found: ".$context->{node});
      goto failure;
    }

    if (!defined $context->{leaf}) {
      $self->{main}->fail
      		("sitemap: leaf content not found: ".$context->{leaf});
      goto failure;
    }

    $output = $self->map_level ($context, $top, 0, undef);
    $self->{main}->del_url ('url');
  }
  $self->{mapping_now} = 0; return $output;

failure:
  $self->{mapping_now} = 0; return "";
}

sub map_level {
  my ($self, $context, $node, $levnum, $upnode) = @_;
  local ($_);

  my $top = $context->{top};
  my $include_gens = $context->{include_generated};
  my $grep = $context->{'grep'};

  return '' if (!$include_gens && $node->is_generated_content());
  my $allkids = '';

  if ($levnum++ > 20) {
    warn "sitemap: stopped recursing at $node->{name}\n";
    return '';
  }

  if ($self->{set_navlinks}) {
    my $prev = $context->{prev};
    if (defined $prev) {
      dbg2 ("nav links: prev=$prev->{name} <--> next=$node->{name}");
      $prev->set_next ($node);
      $node->set_prev ($prev);
    }
    $context->{prev} = $node;

    if (defined $upnode) {
      dbg2 ("nav links: up=$upnode->{name}");
      $node->set_up ($upnode);
    }

    # since we're setting the nav links now, any navigation-related
    # metadata from previous runs is invalid.
    $node->invalidate_cached_nav_metadata();
  }

  my $added_kids = 0;
  foreach my $kid ($node->get_sorted_kids($context->{sortby})) {
    if (!defined $kid) {
      warn "undef kid under ".$node->{name}; next;
    }

    next if (!$include_gens && $kid->is_generated_content());
    next if ($kid eq $top);

    $_ = $kid->{name};
    next if (/^this\./);		# no this.foo metadata thx

    my $PRUNE = 0;
    if (defined $grep) {
      $_ = $kid->{name};
      my $ret = (eval $grep);
      if (!defined $ret) {
	warn "eval failed: { $grep }\n"; return '';
      }
      next if ($ret == 0);
      last if ($PRUNE);
    }

    $allkids .= $self->map_level ($context, $kid, $levnum, $node);
    $added_kids = 1;
  }

  if ($added_kids) {
    return $self->output_node ($context, $node, $levnum, $allkids);
  } elsif ($node->is_generated_content()) {
    return $self->output_dynamic ($context, $node, $levnum);
  } else {
    return $self->output_leaf ($context, $node, $levnum);
  }
}

sub set_per_node_contents {
  my ($self, $context, $node, $haskids) = @_;

  my $title = $node->get_title();
  my $score = $node->get_score();
  my $url = $node->get_url(); $url ||= '';

  $self->{main}->set_transient_content ('title', $title);
  $self->{main}->set_transient_content ('score', $score);
  $self->{main}->set_transient_content ('name', $node->{name});
  $self->{main}->set_transient_content ('is_node', $haskids);
  $self->{main}->add_url ('url', $url);
}

sub output_node {
  my ($self, $context, $node, $levnum, $leafitems) = @_;

  $self->set_per_node_contents ($context, $node, 1);
  $self->{main}->set_transient_content ('list', $leafitems);
  return $self->{main}->curly_subst ($HTML::WebMake::Main::SUBST_EVAL, $context->{node});
}

sub output_leaf {
  my ($self, $context, $node, $levnum) = @_;

  $self->set_per_node_contents ($context, $node, 0);
  return $self->{main}->curly_subst ($HTML::WebMake::Main::SUBST_EVAL, $context->{leaf});
}

sub output_dynamic {
  my ($self, $context, $node, $levnum) = @_;

  $self->set_per_node_contents ($context, $node, 0);
  return $self->{main}->curly_subst ($HTML::WebMake::Main::SUBST_EVAL, $context->{dynamic});
}

# -------------------------------------------------------------------------

1;

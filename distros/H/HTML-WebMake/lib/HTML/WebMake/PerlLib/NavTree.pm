#perl

package HTML::WebMake::PerlLib::NavTree;

use Carp qw(verbose);

sub handle_navtree_tag {
  my ($tagname, $attrs, $text, $self) = @_;

  # just create a content item which calls our function below.
  # we need to use a content item, so that it can be called
  # deferred.
  my $cont = $self->set_content ($attrs->{name}, '<'.'{perl
    HTML::WebMake::PerlLib::NavTree::handle_navtree_reference
      ($self, q{'.$attrs->{name}.'});
  }'.'>');

  # create the navtree handling object (note: could easily
  # just be a function, but the navtree code is more suited
  # to an object). Attach it to the content item so we can
  # find it later!
  $cont->{navtree} = new HTML::WebMake::PerlLib::NavTree ($attrs);

  '';
}

# ---------------------------------------------------------------------------

require Exporter;
use Carp;
use strict;

use vars        qw{
          @ISA @EXPORT
};

@ISA = qw();
@EXPORT = qw();

use HTML::WebMake::Main;
*dbg = \&HTML::WebMake::Main::dbg;

# ---------------------------------------------------------------------------

sub new {
  my $class = shift;
  my $attrs = shift;
  $class = ref($class) || $class;

  my $self = { };
  foreach my $attr (keys %{$attrs}) { $self->{$attr} = $attrs->{$attr}; }
  $self->{'depth'} = 1 unless defined $self->{'depth'};
  $self->{'rootnode'} = $self->{'opennode'} unless defined $self->{'rootnode'};
  bless ($self, $class);
  $self;
}

# ---------------------------------------------------------------------------

sub handle_navtree_reference {
  my ($perlcode, $navtreename) = @_;

  my $self = $perlcode->get_content_object ($navtreename);
  die "cannot find navtree content!" if (!defined $self);
  $self = $self->{navtree};
  die "navtree content has no {navtree} member!" if (!defined $self);

  $self->{perlcode} = $perlcode;

  # first, get the current main content, and convert it to an object
  $self->{current} = $self->{perlcode}->get_content_object
		    ($self->{perlcode}->get_current_main_content());

  # next, evaluate the navmap; this will force the nav to be mapped.
  # Don't count this as a reference to the navmap for URL purposes,
  # otherwise any page which used a <navtree> tag could be marked
  # as the ''main'' navmap page.
  my $navmap = $self->{perlcode}->get_content_object ($self->{sitemap});
  $navmap->expand_no_ref();

  # great! now we can get the root object
  my $root = $self->{perlcode}->get_root_content_object();

  my @family = ($self->{current});
  my $parent = $self->{current};

  while ($parent != $root) {
    $parent = $parent->get_up_content();
    unshift @family, $parent;
  }
  # now @family contains the list of this node, and the parent nodes
  # (including the root), like: ($root, $parent1, $parent2, $current)

  # now display them. This is the hard bit, wrapping it up in a nice
  # tree-structured output.  Most of it's ripped off from the sitemap
  # code, of course, which makes it easier ;)
  #
  return $self->navtree_map_level (0, -1, $self->{depth}, $root, @family);
}

sub navtree_map_level {
    my ($self, $level, $sublvl, $left, $node, $next, @tail) = @_;

    dbg( "navtree_map_level: \$node->name = " . $node->{name} . "\n" .
	"   it has " . ($node->has_any_kids() ? 
	    ("kids: " . join ", ",
		map {$_->{name} . ($_->is_generated_content() ? " (generated)" : " (real)");}
		    $node->get_sorted_kids()) :
	    "no kids") . "\n");
    # don't map generated content (metadata etc.)
    return '' if(!defined $node or $node->is_generated_content());

    if($node == $self->{current}) { # THE CURRENT NODE
	if($node->has_any_kids()) { # It has kids...
	    my $kids = '';
	    if($left > 0) { # ... and we are interested in them.
		for my $kid ($node->get_sorted_kids()) {
		    $kids .= $self->navtree_map_level($level + 1, 1, $left - 1, $kid);
		}
	    }
	    $self->navtree_set_contents($node, $level, 0, $left, 0, $kids);
	    return $self->{perlcode}->get_content($self->{thisnode});
	} # else # no kids...
	$self->navtree_set_contents($node, $level, 0, $left, 1, '');
	return $self->{perlcode}->get_content($self->{thisleaf});
    } # else # OTHER NODE
    if($node->has_any_kids()) { # ... has kids ...
	my $kids = '';
	my ($open, $newsublvl, $newleft);
	my $content = 'closednode';
	($open, $newsublvl, $newleft, $content) = (1, $sublvl + 1, $left - 1, $level ? 'opennode' : 'rootnode')
		if $sublvl >= 0 and $left > 0; # ... and we are interested, because it's ancesor.
	($open, $newsublvl, $newleft, $content) = (1, -1, $left, $level ? 'opennode' : 'rootnode')
		if $sublvl < 0 and $node == $next; # ... and we are interested because it's descendant.
	if($open) {
	    for my $kid ($node->get_sorted_kids()) {
		$kids .= $self->navtree_map_level($level + 1, $newsublvl, $newleft, $kid, @tail);
	    }
	}
	$self->navtree_set_contents($node, $level, $sublvl, $left, 0, $kids);
	return $self->{perlcode}->get_content($self->{$content});
    } # else # No kids.
    $self->navtree_set_contents($node, $level, $sublvl, $left, 1, '');
    return $self->{perlcode}->get_content($self->{leaf});
}

sub navtree_set_contents {
  my ($self, $node, $level, $sublvl, $left, $leaf, $list) = @_;
  $self->{perlcode}->set_content ('title', $node->get_title());
  $self->{perlcode}->set_content ('score', $node->get_score());
  $self->{perlcode}->set_content ('name', $node->get_name());
  $self->{perlcode}->set_url ('url', $node->get_url());
  $self->{perlcode}->set_content ('level', $level);
  $self->{perlcode}->set_content ('sublevel', $sublvl);
  $self->{perlcode}->set_content ('left', $left);
  $self->{perlcode}->set_content ('is_leaf', $leaf);
  $self->{perlcode}->set_content ('list', $list);
}

1;

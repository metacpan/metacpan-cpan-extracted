#perl

package HTML::WebMake::PerlLib::SiteTree;

sub handle_sitetree_tag {
  my ($tagname, $attrs, $text, $self) = @_;

  # just create a content item which calls our function below.
  # we need to use a content item, so that it can be called
  # deferred.
  my $cont = $self->set_content ($attrs->{name}, '<'.'{perl
    HTML::WebMake::PerlLib::SiteTree::handle_sitetree_reference
      ($self, q{'.$attrs->{name}.'});
  }'.'>');

  # create the sitetree handling object (note: could easily
  # just be a function, but the sitetree code is more suited
  # to an object). Attach it to the content item so we can
  # find it later!
  $cont->{sitetree} = new HTML::WebMake::PerlLib::SiteTree ($attrs);

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

# ---------------------------------------------------------------------------

sub new {
  my $class = shift;
  my $attrs = shift;
  $class = ref($class) || $class;

  my $self = { };
  foreach my $attr (%{$attrs}) { $self->{$attr} = $attrs->{$attr}; }
  bless ($self, $class);
  $self;
}

# ---------------------------------------------------------------------------

sub handle_sitetree_reference {
  my ($perlcode, $sitetreename) = @_;

  my $self = $perlcode->get_content_object ($sitetreename);
  die "cannot find sitetree content!" if (!defined $self);
  $self = $self->{sitetree};
  die "sitetree content has no {sitetree} member!" if (!defined $self);

  $self->{perlcode} = $perlcode;

  # first, get the current main content, and convert it to an object
  $self->{current} = $self->{perlcode}->get_content_object
		    ($self->{perlcode}->get_current_main_content());

  # next, evaluate the sitemap; this will force the site to be mapped.
  # Don't count this as a reference to the sitemap for URL purposes,
  # otherwise any page which used a <sitetree> tag could be marked
  # as the ''main'' sitemap page.
  my $sitemap = $self->{perlcode}->get_content_object ($self->{sitemap});
  $sitemap->expand_no_ref();

  # great! now we can get the root object
  my $root = $self->{perlcode}->get_root_content_object();


  $self->{family} = [ $self->{current} ];
  my $parent = $self->{current};

  while ($parent != $root) {
    $parent = $parent->get_up_content();
    unshift (@{$self->{family}}, $parent);
  }
  # now @family contains the list of this node, and the parent nodes
  # (including the root), like: ($root, $parent1, $parent2, $current)

  # now display them. This is the hard bit, wrapping it up in a nice
  # tree-structured output.  Most of it's ripped off from the sitemap
  # code, of course, which makes it easier ;)
  #
  return $self->sitetree_map_level ($root);
}

sub sitetree_map_level {
  my ($self, $node) = @_;
  my $out = '';

  # don't map generated content (metadata etc.)
  if (!defined $node || $node->is_generated_content()) { return ''; }

  if ($node == $self->{current}) {
    # this page! Mark it as the 'leaf'
    $self->sitetree_set_contents ($node);
    $out .= $self->{perlcode}->get_content ($self->{thispage});

  } elsif (!$node->has_any_kids()) {
    # it has no kids
    $self->sitetree_set_contents ($node);
    $out .= $self->{perlcode}->get_content ($self->{leaf});

  } elsif (grep { $_ == $node } @{$self->{family}}) {
    # it's on our path, recurse into it, then map it
    my $leafitems = '';
    
    foreach my $kid ($node->get_sorted_kids()) {
      $leafitems .= $self->sitetree_map_level ($kid);
    }

    $self->{perlcode}->set_content ('list', $leafitems);
    $self->sitetree_set_contents ($node);
    $out .= $self->{perlcode}->get_content ($self->{opennode});

  } else {
    # it's not on our path, map it as 'closed'
    $self->sitetree_set_contents ($node);
    $out .= $self->{perlcode}->get_content ($self->{closednode});
  }

  return $out;
}

sub sitetree_set_contents {
  my ($self, $node) = @_;
  $self->{perlcode}->set_content ('title', $node->get_title());
  $self->{perlcode}->set_content ('score', $node->get_score());
  $self->{perlcode}->set_content ('name', $node->get_name());
  $self->{perlcode}->set_url ('url', $node->get_url());
}

1;

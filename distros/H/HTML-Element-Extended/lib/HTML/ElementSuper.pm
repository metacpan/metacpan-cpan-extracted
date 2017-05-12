package HTML::ElementSuper;

# Extend the HTML::Element class to allow the following:
#    positional reporting
#    content replacement
#    masking (i.e., in the structure but invisible to traverse)
#    content wrapping
#    cloning of self and arbitrary elements

use strict;
use vars qw($VERSION @ISA $AUTOLOAD);
use Carp;
use Data::Dumper;

# Make sure we have access to the new methods. These were added sometime
# in early 2000 but we'll just anchor off of the new numbering system.
use HTML::Element 3.01;

@ISA = qw(HTML::Element);

$VERSION = '1.18';

### attr extension ###

sub push_attr {
  my $self = shift;
  my($attr, @new) = @_;
  my(%seen, @vals);
  if (defined(my $spec = $self->attr($attr))) {
    for my $v (split(/\s+/, $spec)) {
      next if $seen{$v};
      push(@vals, $seen{$v} = $v);
    }
  }
  for my $v (grep { defined $_ } @new) {
    next if $seen{$v};
    push(@vals, $seen{$v} = $v);
  }
  $self->SUPER::attr($attr, join(' ', @vals));
}

### positional extension ###

sub addr {
  my $self = shift;
  my $p = $self->parent;
  return undef unless $p;
  my @sibs = $p->content_list;
  foreach my $i (0..$#sibs) {
    return $i if defined $sibs[$i] && $sibs[$i] eq $self;
  }
  Carp::confess "major oops, no addr found for $self\n";
}

sub position {
  # Report coordinates by chasing addr's up the HTML::ElementSuper tree.
  # We know we've reached the top when a) there is no parent, or b) the
  # parent is some HTML::Element unable to report it's position.
  my $p = shift;
  my @pos;
  while ($p) {
    my $pp = $p->parent;
    last unless ref $pp && $pp->isa(__PACKAGE__);
    my $a = $p->addr;
    unshift(@pos, $a) if defined $a;
    $p = $pp;
  }
  @pos;
}

sub depth {
  my $self = shift;
  my $depth = 0;
  my $p = $self;
  while ($p = $p->parent) {
    ++$depth;
  }
  $depth;
}

# Handy debugging tools

sub push_position {
  # Push positional coordinates into own content
  my $self = shift;
  $self->push_content(' (' . join(',', $self->position) . ')');
}

sub push_depth {
  # Push HTML tree depth into own content
  my $self = shift;
  $self->push_content('(' . $self->depth . ')');
}

### cloner extension ###

sub clone {
  # Clone HTML::Element style trees.
  # Clone self unless told otherwise.
  # Cloning comes in handy when distributing methods such as
  # push_content - you don't want the same HTML::Element tree across
  # multiple nodes, just a copy of it - since HTML::Element nodes only
  # recognize one parent.
  #
  # Note: The new cloning functionality of HTML::Element is insufficent
  #       for our purposes. Syntax aside, the native clone() does not
  #       clone the element globs associated with a table...the globs
  #       continue to affect the original element structure.
  my $self = shift;
  my @args = @_;

  @args || push(@args, $self);
  my($clone, $node, @clones);
  my($VAR1, $VAR2, $VAR3);
  $Data::Dumper::Purity = 1;
  foreach $node (@args) {
    _cloning($node, 1);
    eval(Dumper($node));
    carp("$@ $node") if $@;
    _cloning($node, 0);
    _cloning($VAR1, 0);
    # Retie the watchdogs
    $VAR1->traverse(sub {
                      my($node, $startflag) = @_;
                      return unless $startflag;
                      if ($node->can('watchdog')) {
                        $node->watchdog(1);
                        $node->watchdog->mask(1) if $node->mask;
                      }
                      1;
                    }, 'ignore_text') if ref $VAR1;
    push(@clones, $VAR1);
  }
  $#clones ? @clones : $clones[0];
}

sub _cloning {
  # Ugh. We need to do this when we clone and happen to be masked,
  # otherwise masked content will not make it into the clone.
  my $node = shift;
  return unless ref $node;
  if (@_) {
    if ($_[0]) {
      $node->traverse(sub {
                        my($node, $startflag) = @_;
                        return unless $startflag;
                        $node->_clone_state(1) if $node->can('_clone_state');
                        1;
                      }, 'ignore_text');
    }
    else {
      $node->traverse(sub {
                        my($node, $startflag) = @_;
                        return unless $startflag;
                        $node->_clone_state(0) if $node->can('_clone_state');
                        1;
                      }, 'ignore_text');      
    }
  }
  $node->can('watchdog') && $node->watchdog ? $node->watchdog->cloning : 0;
}

sub _clone_state {
  my($self, $state) = @_;
  return 0 unless $self->watchdog;
  if (defined $state) {
    if ($state) {
      $self->watchdog->cloning(1);
    }
    else {
      $self->watchdog->cloning(0);
    }
  }
  $self->watchdog->cloning;
}


### maskable extension ###

sub mask {
  my($self, $mode) = @_;
  if (defined $mode) {
    # We count modes since masking can come from overlapping influences,
    # theoretically.
    if ($mode) {
      if (! $self->{_mask}) {
        # deactivate (mask) content
        $self->watchdog(1) unless $self->watchdog;
        $self->watchdog->mask(1);
      }
      ++$self->{_mask};
    }
    else {
      --$self->{_mask} unless $self->{_mask} <= 0;
      if (! $self->{_mask}) {
        # activate (unmask) content
        if ($self->watchdog_listref) {
          $self->watchdog->mask(0);
        }
        else {
          $self->watchdog(0);
        }
      }
    }
  }
  $self->{_mask};
} 

sub starttag {
  my $self = shift;
  return '' if $self->mask;
  $self->SUPER::starttag(@_);
}

sub endtag {
  my $self = shift;
  return '' if $self->mask;
  $self->SUPER::endtag(@_);
}

sub starttag_XML {
  my $self = shift;
  return '' if $self->mask;
  $self->SUPER::starttag_XML(@_);
}

sub endtag_XML {
  my $self = shift;
  return '' if $self->mask;
  $self->SUPER::endtag_XML(@_);
}

# Oh, the horror! This used to be all that was necessary to implement
# masking -- overriding traverse. But the new HTML::Element does NOT
# call traverse on a per-element basis, so now when we're masked we have
# to play dead -- no tags, no content. To make matters worse, we can't
# just override the content method because the new traverse()
# implentation is playing directly wiht the data structures rather than
# calling content().
#
# See below for the current solution: HTML::ElementSuper::TiedContent
#
# For the time being, I've kept the old code and commentary here:
#
## Routines that use traverse, such as as_HTML, are not called
## on a per-element basis.  as_HTML always belongs to the top level
## element that initiated the call.  A maskable element should not
## be seen, though.  Overriding as_HTML will not do the trick since
## we cannot guarantee that the top level element is a maskable-aware
## element with the overridden method.  Therefore, for maskable
## elements, we override traverse itself, which does get called on a
## per-element basis. If this element is masked, simply return from
## traverse, making this element truly invisible to parents.  This
## means that traverse is no longer guranteed to actually visit all
## elements in the tree. For that, you must rely on the actual
## contents of each element.
#sub traverse {
#  my $self = shift;
#  return if $self->mask;
#  $self->SUPER::traverse(@_);
#}
#
#sub super_traverse {
#  # Saftey net for catching wayward masked elements.
#  my $self = shift;
#  $self->SUPER::traverse(@_);
#}

### replacer extension ###

sub replace_content {
  my $self = shift;
  $self->delete_content;
  $self->push_content(@_);
}

### wrapper extension ###

sub wrap_content {
  my($self, $wrap) = @_;
  my $content = $self->content;
  if (ref $content) {
    $wrap->push_content(@$content);
    @$content = ($wrap);
  }
  else {
    $self->push_content($wrap);
  }
  $wrap;
}

### watchdog extension ###

sub watchdog_listref {
  my $self = shift;
  @_ ? $self->{_wa} = shift : $self->{_wa};
}

sub watchdog {
  my $self = shift;
  if (@_) {
    if ($_[0]) {
      # Install the watchdog hash
      my $wa = shift;
      if (ref $wa eq 'ARRAY') {
        $self->watchdog_listref($wa);
      }
      else {
        $wa = $self->watchdog_listref;
      }
      my $cr = $self->content;
      my @content = @$cr;
      @$cr = ();
      $self->{_wd} = tie @$cr, 'HTML::ElementSuper::ContentWatchdog';
      @$cr = @content;
      $self->{_wd}->watchdog($wa) if ref $wa eq 'ARRAY';
    }
    else {
      # Release the watchdog
      my @content = $self->{_wd}->fetchall; # in case it's masked
      my $cr = $self->content;
      # Delete obj ref before untie in order to hush -w
      delete $self->{_wd};
      untie @$cr;
      @$cr = @content;
    }
  }
  $self->{_wd};
}

###

sub new {
  my $that = shift;
  my $class = ref($that) || $that;
  my $self = $class->SUPER::new(@_);
  # force init of content with array ref
  $self->content_array_ref;
  bless $self,$class;
  $self;
}

### deprecated ###

sub delete_attr {
  # Deprecated by new HTML::Element functionality. Should now use
  # attr($attr, undef) for attribute deletions. Still returning the old
  # value here for backwards compatability.
  my($self, $attr) = @_;
  $attr = lc $attr;
  my $old = $self->attr($attr);
  $self->attr($attr, undef);
  $old;
}

### temporary Overrides (until bugs fixed in HTML::Element) ###

sub replace_with {
  my $self = shift;
  my $p = $self->parent;
  $self->SUPER::replace_with(@_);
  grep { $_->parent($p) } @_;
  $self;
}

### bag o kludgy tricks ###

{
  package HTML::ElementSuper::ContentWatchdog;

  use strict;
  use Carp;
  use vars qw( @ISA );
  use Tie::Array;
  @ISA = qw( Tie::Array );

  # I got tired of jumping through hoops dealing with the new
  # HTML::Element semantics. Since I could no longer override traverse()
  # I was having to go through all sorts of contortions to "hide"
  # elements in the tree when masked. In a cohesive tree like
  # HTML::ElementTable, this was still insufficient because globbed
  # access to the masked elements still needed to be retained.
  #
  # The hoops in question involved either a) breaking containment all
  # over the place, or b) overriding *all* content methods, or c)
  # swapping in a doppleganger element for the masked element, which
  # then involved overriding just about everything since the positional
  # methods needed to look at the doppleganger, but everything else
  # needed to look at the original.
  #
  # So here I provide a class for tying the content array and doing the
  # right thing when masked. Note that starttag() and endtag() still
  # need to be overridden, but this tied class should take care of
  # traverse rifling through masked content.
  #
  # Note that all content manipulation works as expected, except for
  # FETCH. This is intentional.
  #
  # Technically, this is not breaking containment since the content()
  # method returns the content array reference. Even though this is a
  # read-only method, we can still tie() over the array pointed to by
  # the reference!
  #
  # See mask() for implementation.
  #
  # I'll probably go to programmer hell for this, but what the hey.
  #
  # UPDATE: Since I was already doing this for masking, I decided to to
  # general content policing with the same mechanism, but only when
  # requested via the watchdog parameter, passed as a code reference.
  # Alas, this meant a full implmentation rather than just subclassing
  # Tie::StdArray and overriding FETCH().

  # Object methods

  sub fetchall { @{shift->{_array}} }

  sub watchdog {
    my($self, $classes_ref) = @_;
    if ($classes_ref) {
      $self->{watchdog} = {};
      foreach (@$classes_ref) {
        ++$self->{watchdog}{$_};
      }
    }
    $self->{watchdog};
  }

  sub permit {
    my($self, @objects) = @_;
    return 1 unless $self->{watchdog};
    foreach (@objects) {
      my $type = ref($_) || $_;
      croak "Adoption of type $type, which is not of type " .
        join(', ', sort keys %{$self->{watchdog}}) . "\n"
          unless $self->{watchdog}{$type};
    }
    1;
  }

  sub mask {
    my $self = shift;
    @_ ? $self->{mask} = shift : $self->{mask};
  }

  sub cloning {
    my $self = shift;
    @_ ? $self->{cloning} = shift : $self->{cloning};
  }

  # Tied array methods

  sub TIEARRAY {
    my $that = shift;
    my $class = (ref $that) || $that;
    my $self = {};
    bless $self, $class;
    %$self = @_;
    $self->{_array} = [];
    $self;
  }

  sub FETCH {
    my($self, $k) = @_;
    return if $self->{mask} && !$self->{cloning};
    $self->{_array}[$k];
  }

  sub STORE {
    my($self, $k, $v) = @_;
    my $vc = ref $v;
    $self->permit($v) if $self->{watchdog};
    $self->{_array}[$k] = $v;
  }

  sub PUSH {
    my $self = shift;
    $self->permit(@_) if $self->{watchdog};
    push(@{$self->{_array}}, @_);
  }

  sub UNSHIFT {
    my $self = shift;
    $self->permit(@_) if $self->{watchdog};
    unshift(@{$self->{_array}}, @_);
  }

  sub SPLICE {
    my($self, $offset, $length, @list) = @_;
    if (@list && $self->{watchdog}) {
      $self->permit(@list);
    }
    splice(@{$self->{_array}}, @_);
  }

  #### The rest of these are just native ops on the inner array.

  sub FETCHSIZE { scalar @{shift->{_array}} }
  sub STORESIZE {
    my($self, $size) = @_;
    $#{$self->{_array}} = $size - 1;
  }
  sub CLEAR {       @{shift->{_array}} = () }
  sub POP   {   pop(@{shift->{_array}})     }
  sub SHIFT { shift(@{shift->{_array}})     }

} ### End HTML::ElementSuper::ContentWatchdog

1;
__END__

=head1 NAME

HTML::ElementSuper - Perl extension for HTML::Element(3)

=head1 SYNOPSIS

  use HTML::ElementSuper;

  ### Positional extension
  $e = new HTML::ElementSuper 'font';
  $sibling_number = $e->addr();
  $e2 = new HTML::ElementSuper 'p';
  $e2->push_content($e);
  # 
  @coords = $e->position();
  $depth_in_pos_tree = $e->depth();

  ### Replacer extension
  $er = new HTML::ElementSuper 'font';
  # Tree beneath $er, if present, is dropped.
  $er->replace_content(new HTML::Element 'p');

  ### Wrapper extension
  $ew = new HTML::ElementSuper;
  $ew->push_content("Tickle me, baby");
  $ew->wrap_content(new HTML::Element 'font', color => 'pink');
  print $ew->as_HTML();

  ### Maskable extension
  $em = new HTML::ElementSuper 'td';
  $em->mask(1);
  print $em->as_HTML; # nada
  $em->mask(0);
  print $em->as_HTML; # $e and its children are visible

  ### Cloning of own tree or another element's tree
  ### (is this the correct clomenature?  :-)
  $a = new HTML::ElementSuper 'font', size => 2;
  $b = new HTML::ElementSuper 'font', color => 'red';
  $a_clone  = $a->clone;
  $b_clone = $a->clone($b);
  # Multiple elements can be cloned
  @clone_clones = $a_clone->clone($a_clone, $b_clone);


=head1 DESCRIPTION

HTML::ElementSuper is an extension for HTML::Element(3) that provides
several new methods to assist in element manipulation. An
HTML::ElementSuper has the following additional properties:

   * report is coordinate position in a tree of its peers
   * replace its contents
   * wrap its contents in a new element
   * mask itself so that it and its descendants are invisible to
     traverse()
   * clone itself and other HTML::Element based object trees
   * handle multiple values for attributes

Note that these extensions were originally developed to assist in
implementing the HTML::ElementTable(3) class, but were thought to be of
general enough utility to warrant their own package.

=head1 METHODS

=over

=item new('tag', attr => 'value', ...)

Return a new HTML::ElementSuper object. Exactly like the constructor for
HTML::Element(3), takes a tag type and optional attributes.

=item push_attr(attr => @values)

Extend the value string for a particular attribute. An example of this
might be when you'd like to assign multiple CSS classes to a single
element. The attribute value is extended using white space as a
separator.

=item addr()

Returns the position of this element in relation to its siblings based
on the content of the parent, starting with 0. Returns undef if this
element has no parent. In other words, this returns the index of this
element in the content array of the parent.

=item position()

Returns the coordinates of this element in the tree it inhabits. This is
accomplished by succesively calling addr() on ancestor elements until
either a) an element that does not support these methods is found, or b)
there are no more parents. The resulting list is the n-dimensional
coordinates of the element in the tree.

=item replace_content(@new_content)

Simple shortcut method that deletes the current contents of the element
before adding the new.

=item wrap_content($wrapper_element)

Wraps the existing content in the provided element. If the
provided element happens to be a non-element, a push_content is
performed instead.

=item mask

=item mask(mode)

Toggles whether or not this element is visible to parental methods that
visit the element tree using traverse(), such as as_HTML(). Valid
arguments for mask() are 0 and 1. Returns the current setting without
an argument.

This might seem like a strange method to have, but it helps in managing
dynamic tree structures. For example, in HTML::ElementTable(3), when
you expand a table cell you simply mask what it covers rather than
destroy it. Shrinking the table cell reveals that content to as_HTML()
once again.

=item clone

=item clone(@elements)

Returns a clone of elements and all of their descendants. Without
arguments, the element clones itself, otherwise it clones the elements
provided as arguments. Any element can be cloned as long as it is
HTML::Element(3) based. This method is very handy for duplicating tree
structures since an HTML::Element cannot have more than one parent at
any given time...hence "tree".

=back

=head1 REQUIRES

HTML::Element(3), Data::Dumper(3)

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1998-2010 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

HTML::Element(3), HTML::ElementGlob(3), HTML::ElementRaw(3), HTML::ElementTable(3), perl(1).

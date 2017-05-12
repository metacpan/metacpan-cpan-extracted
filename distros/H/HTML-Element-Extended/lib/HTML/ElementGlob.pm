package HTML::ElementGlob;

use strict;
use vars qw($VERSION $AUTOLOAD);

use HTML::ElementSuper;

$VERSION = '1.18';

####################################################
# glob_* methods do the HTML::Element type methods #
# on the glob structure itself, rather than muxing #
# the methods to its children. Most of these are   #
# taken care of in AUTOLOAD, but we override some. #
####################################################

sub glob_delete_content {
  # Do not propogate delete_content to children, as
  # this should be the job of the real parent.
  my $self = shift;
  @{$self->glob_content} = () unless $self->glob_is_empty;
  $self;
}

sub glob_delete {
  # Do not propogate delete to children, either.
  my $self = shift;
  $self->glob_delete_content;
  %{$self} = ();
}

sub context_is_glob {
  # The newer HTML::Element class invokes detach() quite a bit
  # during content operations -- *without* prepending glob_,
  # obviously.  We have to have some way of indicating to children
  # globs that they should NOT broadcast methods to children --
  # otherwise, all the regular elements in the child glob will get
  # detach() invoked as well. So...if a glob knows it is about to
  # perform an operation on another glob that should not be
  # broadcast -- set this flag, then unset it afterwards.
  my $self = shift;
  @_ ? $self->{_context_is_glob} = shift : $self->{_context_is_glob};
}

######################################################
# MUXed methods (pass invocation to children)        #
# Some methods do not really make sense in a globbed #
# context, so we try to 'do the right thing' here.   #
######################################################

# HTML::Element based methods
sub push_content    { shift->_content_manipulate('push_content', @_) }
sub unshift_content { shift->_content_manipulate('unshift_content', @_) }
sub splice_content  { shift->_content_manipulate('splice_content', @_) }
# replace_with_content does not apply, as elements are not passed
# in the argument list, they are summoned from each individual
# element's content.

# HTML::ElementSuper based methods
sub wrap_content    { shift->_content_manipulate('wrap_content', @_) }
sub replace_content { shift->_content_manipulate('replace_content', @_) }

sub _content_manipulate {
  # Generic method for cloning and broadcasting the
  # element trees provided to content methods
  my $self = shift;
  my $name = shift;
  my @children = $self->{_element}->content_list;
  # Find the first child that will have the method
  # invoked.
  my $first = undef;
  foreach (0 .. $#children) {
    if (ref $children[$_]) {
      $first = $_;
      last;
    }
  }
  return undef unless defined $first;
  # Deal with the tail elements first
  if ($first < $#children) {
    foreach ($first+1 .. $#children) {
      next unless ref $children[$_];
      $children[$_]->$name($self->{_element}->clone(@_));
    }
  }
  # First child can have the real copy
  $children[$first]->$name(@_);
}

# Constructor

sub new {
  my $that = shift;
  my $class = ref($that) || $that;
  my $self = {};
  bless $self,$class;
  $self->{_element}    = new HTML::ElementSuper @_;
  $self->{_babysitter} = new HTML::ElementSuper @_;
  $self;
}

sub AUTOLOAD {
  # Methods starting with glob deal with glob management,
  # otherwise they get passed blindly to all children unless
  # they have been overridden above.
  my $self = shift;
  my $name = $AUTOLOAD;
  $name =~ s/.*:://;
  return if $name =~ /^DESTROY/;

  # First, deal with glob_* induced methods
  if ($name =~ s/^glob_//) {
    # First, indicate to other globs that subsequent method
    # calls are glob_ induced.
    foreach (grep { ref $_ eq ref $self } @_) {
      $_->context_is_glob(1);
    }
    # Store the pedigree of all elements, including globs,
    # since no matter what a glob does it should not disturb
    # the original lineage of an element.  With the new
    # HTML::Element, detach() gets called which also
    # adjusts the content of the parent if available,
    # so we give them to the babysitter for now (there
    # is no publicly available method for just dropping
    # a parent, and I'm loathe to mess with internal state
    # variables and break containment on HTML::Element)
    my @result;
    my %parents;
    for (grep { ref $_->parent } grep { ref $_ } @_) {
      next if $parents{$_};
      $parents{$_} = $_->parent;
      $_->parent($self->{_babysitter});
    }
    # Invoke the method on our internal element
    @result = $self->{_element}->$name(@_);
    # Restore the lineages.

    for (grep { ref $_ } @_) {
      $_->parent(delete $parents{$_}) if $parents{$_};
    }
    # Cancel glob_ induced context.
    foreach (grep { ref $_ eq ref $self } @_) {
      $_->context_is_glob(0);
    }
    return wantarray ? @result : $result[$#result];
  }
  elsif ($self->context_is_glob) {
    # Here, we have intercepted a native method call that should
    # actually be executing in glob_ context -- so we do so in
    # order to ensure any overriden glob_* methods get properly
    # invoked.
    $name = "glob_$name";
    return $self->$name(@_);
  }

  # Otherwise broadcast to component elements.
  if (!$self->{_element}->is_empty) {
    my @results;
    foreach (grep { ref $_ } $self->{_element}->content_list) {
      push(@results, $_->$name(@_));
    }
    return @results;
  }
}

1;
__END__

=head1 NAME

HTML::ElementGlob - Perl extension for managing HTML::Element based objects as a single object.

=head1 SYNOPSIS

  use HTML::ElementGlob;
  $element_a = new HTML::Element 'font', color => 'red';
  $element_b = new HTML::Element 'font', color => 'blue';
  $element_a->push_content('red');
  $element_b->push_content('blue');

  $p = new HTML::Element 'p';
  $p->push_content($element_a, ' and ', $element_b, ' boo hoo hoo');

  # Tag type of the glob is not really relevant unless
  # you plan on seeing the glob as_HTML()
  $eglob = new HTML::ElementGlob 'p';
  $eglob->glob_push_content($element_a, $element_b);
  # Alter both elements at once
  $eglob->attr(size => 5);

  # They still belong to their original parent
  print $p->as_HTML;

=head1 DESCRIPTION

HTML::ElementGlob is a managing object for multiple
HTML::Element(3) style elements.  The children of the glob
element retain their original parental elements and have
no knowledge of the glob that manipulates them.  All methods
that do not start with 'glob_' will be passed, sequentially, to
all elements contained within the glob element.  Methods
starting with 'glob_' will operate on the glob itself, rather
than being passed to its foster children.

For example, $eglob->attr(size => 3) will invoke attr(size => 3) on
all children contained by $eglob.  $eglob->glob_attr(size => 3), on
the other hand, will set the attr attribute on the glob itself.

The tag type passed to HTML::Element::Glob is largely
irrrelevant as far as how methods are passed to children.  However,
if you choose to invoke $eglob->as_HTML(), you might want to pick
a tag that would sensibly contain the globbed children for debugging
or display purposes.

The 'glob_*' methods that operate on the glob itself are limited
to those available in an HTML::Element(3).  All other methods get
passed blindly to the globbed children, which can be enhanced elements
with arbitrary methods, such as HTML::ElementSuper(3).

Element globs can contain other element globs.  In such cases, the
plain methods will cascade down to the leaf children.  'glob_*' methods,
of course, will not be propogated to children globs.  You will
have to rely on glob_content() to access those glob children and
access their 'glob_*' methods directly.

=head1 REQUIRES

HTML::ElementSuper(3)

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1998-2010 Matthew P. Sisk.
All rights reserved. All wrongs revenged. This program is free
software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

HTML::Element(3), HTML::ElementSuper, HTML::ElementRaw, HTML::Element::Table(3), perl(1).

=cut

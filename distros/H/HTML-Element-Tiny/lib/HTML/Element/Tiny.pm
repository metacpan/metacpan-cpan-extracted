use strict;
local $^W = 1;

package HTML::Element::Tiny;

use vars qw($VERSION %HAS @TAGS %DEFAULT_CLOSED %DEFAULT_NEWLINE %TAG_CLASS);
$VERSION = '0.006';
use 5.004;
BEGIN {
#  @TAGS = 
#      qw( a abbr acronym address area b base bdo big blockquote body br
#      button caption cite code col colgroup dd del div dfn dl dt em
#      fieldset form frame frameset h1 h2 h3 h4 h5 h6 head hr html i
#      iframe img input ins kbd label legend li link map meta noframes
#      noscript object ol optgroup option p param pre q samp script select
#      small span strong style sub sup table tbody td textarea tfoot th
#      thead title tr tt ul var );
  %DEFAULT_CLOSED = map { $_ => 1 }
    qw( area base br col frame hr img input meta param link );
  %DEFAULT_NEWLINE = map { $_ => 1 }
    qw( html head body div p tr table );
  use vars qw(%_modver);
  %_modver = (
    Clone => '0.28',
  );
  for my $module (qw(HTML::Entities Clone)) {
    my $modver = $_modver{$module} || 0;
    $HAS{$module} = eval "use $module $modver (); 1"
      unless defined $HAS{$module};
  }
}

use Scalar::Util ();
use Carp ();

#use overload (
#  q{""} => 'as_string',
#  q{0+} => sub { Scalar::Util::refaddr($_[0]) },
#  fallback => 1,
#);

sub TAG      () { 0 }
sub ID       () { 1 }
sub CLASS    () { 2 }
sub ATTR     () { 3 }
sub CHILDREN () { 4 }

%TAG_CLASS = (
  -text    => "-Text",
  -base    => 'HTML::Element::Tiny',
  -default => 'HTML::Element::Tiny',
);

sub _tag_class {
  my ($class, $tag) = @_;
  my $tag_lookup;
  {
    no strict 'refs';
    if (exists ${$class . '::'}{TAG_CLASS}
      and *{${$class . '::'}{TAG_CLASS}}{HASH}) {
      $tag_lookup = \%{$class . '::TAG_CLASS'};
      # XXX should this really be the case? it seems like a very sane default.
      $tag_lookup->{-base}    ||= $class;
      $tag_lookup->{-default} ||= $class;
    } else {
      $tag_lookup = {};
    }
  }
  my $tag_class;
  for my $href ($tag_lookup, \%TAG_CLASS) {
    if ($tag_class = $href->{$tag}) {
      $tag_class =~ s/^-/$href->{-base}::/;
      last;
    }
  }
  $tag_class ||= $tag_lookup->{-default} || $TAG_CLASS{-default};
      
  return $tag_class;
} 

sub new {
  my ($class, $arg, $extra) = @_;
  unless (ref $arg) {
    return bless \$arg => _tag_class($class, '-text');
  }
  Carp::confess "no tag: @$arg" unless @$arg;
  my $tag = shift @$arg;
  my $attr = ref $arg->[0] eq 'HASH' ? shift @$arg : {};
  @{$attr}{keys %$extra} = (values %$extra) if $extra;
  my $self = bless [
    $tag,
    delete $attr->{id},
    [ split /\s+/, delete $attr->{class} || '' ],
    $attr,
    [ ],
  ] => _tag_class($class, $tag);
  Scalar::Util::weaken($self->[ATTR]->{-parent})
    if $self->[ATTR]->{-parent};
  @{$self->[CHILDREN]} = map { $class->new($_, { -parent => $self }) } @$arg;
  return $self;
}

sub children { @{$_[0]->[CHILDREN]} }
sub parent   { $_[0]->[ATTR]->{-parent} }
sub tag      { $_[0]->[TAG] }
sub id       { $_[0]->[ID] }
sub class    { join " ", @{$_[0]->[CLASS]} }
sub classes  { @{$_[0]->[CLASS]} } 

# _match needs to use accessors despite being internal because it may touch
# non-arrayref subclasses like -Text
sub _match {
  my ($self, $spec) = @_;
  return (
    (defined $spec->{id}  ? $spec->{id}  eq ($self->id || '') : 1) &&
    ($spec->{-tag} ? $spec->{-tag} eq ($self->tag)      : 1) &&
    ($spec->{class} ? (
      # 'there are no parts of $spec->{class} that do not have a matching
      # entry in $self->classes' -- easier than saying all/all
      ! grep {
        my $c = $_;
        ! grep { $_ eq $c } $self->classes
      } split /\s+/, $spec->{class}
    ) : 1) &&
    (! grep { 
      $_ ne 'id' and $_ ne '-tag' and $_ ne 'class' and
      $spec->{$_} ne ($self->attr($_) || '')
    } keys %$spec)
  );
}

sub _spec_to_str { 
  my $spec = shift;
  return join " ", map { "$_=$spec->{$_}" } sort keys %$spec;
}

sub _iter (&) { bless $_[0] => 'HTML::Element::Tiny::Iterator' }
sub _coll (@) { HTML::Element::Tiny::Collection->new(@_) }

sub find_iter {
  my ($self, $spec) = @_;
  my $iter = $self->iter;
  return _iter {
    {
      return unless defined(my $next = $iter->next);
      redo unless $next->_match($spec);
      return $next;
    }
  };
}

sub find {
  my ($self, $spec) = @_;
  # id should short-circuit
  return grep( { defined && length } $spec->{id} )
    ? _coll($self->find_iter($spec)->next)
    : $self->all->filter($spec);
}

sub find_one {
  my ($self, $spec) = @_;
  my $iter = $self->find_iter($spec);
  my $elem = $iter->next;
  unless ($elem) {
    Carp::croak "no element found for " . _spec_to_str($spec);
  }
  if (my $next = $iter->next) {
    Carp::croak "not exactly one element: found $elem, $next";
  }
  return $elem;
}

sub all {
  return _coll($_[0]->_all);
}

sub _all {
  my $self = shift;
  return $self, map({ $_->_all } $self->children );
}
  
sub iter {
  my $self = shift;
  my @queue = $self;
  return _iter { 
    return unless @queue;
    my $next = shift @queue;
    unshift @queue, $next->children;
    return $next;
  };
}

sub attr {
  my ($self, $arg) = @_;
  if (ref $arg eq 'HASH') {
    while (my ($k, $v) = each %$arg) {
      if ($k eq 'id')       { $self->[ID] = $v }
      elsif ($k eq 'class') { @{$self->[CLASS]} = split /\s+/, $v; }
      else                  { $self->[ATTR]->{$k} = $v; }
    }
    return $self;
  } elsif (not ref $arg) {
    return $self->[ID]  if $arg eq 'id';
    return $self->class if $arg eq 'class';
    return $self->[ATTR]->{$arg};
  }
  Carp::croak "invalid argument to attr(): '$arg' (must be hashref or scalar)";
}

sub _Clone_clone {
  my ($self, $extra) = @_;
  my $clone = Clone::clone($self);
  delete $clone->[ATTR]->{-parent};
  $clone->attr($extra) if $extra and %$extra;
  return $clone;
}

sub _my_clone {
  my ($self, $extra) = @_;
  my %attr = %{$self->[ATTR]};
  delete $attr{-parent};
  my $clone = bless [
    $self->[TAG],
    $self->[ID],
    [ $self->classes ],
    { %attr, %{$extra || {}} },
    [],
  ] => ref $self;
  $clone->append($self->children);
  return $clone;
}

my $clone_type = sprintf "_%s_clone", (grep { $HAS{$_} } qw(Clone))[0] || 'my';
sub clone {
  my ($self, $extra) = @_;
  my $clone = do { no strict 'refs'; &$clone_type($self, $extra) };

  Scalar::Util::weaken($clone->[ATTR]->{-parent})
    if $clone->[ATTR]->{-parent};
  return $clone;
}

sub _new_children {
  my $self = shift;
  return map {
    Scalar::Util::blessed($_)
      ? $_->parent
        ? $_->clone({ -parent => $self })
        : $_->attr({ -parent => $self })
      : ref($self)->new($_, { -parent => $self })
  } @_;
}

sub prepend {
  my $self = shift;
  unshift @{ $self->[CHILDREN] }, $self->_new_children(@_);
}
    
sub append {
  my $self = shift;
  push @{ $self->[CHILDREN] }, $self->_new_children(@_);
}

sub remove_child {
  my $self = shift;
  my (%idx, %obj);
  for (@_) {
    if (Scalar::Util::blessed($_)) {
      $obj{Scalar::Util::refaddr($_)}++;
    } else {
      $idx{$_}++;
    }
  }
  my @children;
  my @removed;
  for my $i (0..$#{$self->[CHILDREN]}) {
    my $child = $self->[CHILDREN]->[$i];
    if ($idx{$i} or $obj{Scalar::Util::refaddr($child)}) {
      $child->attr({ -parent => undef });
      push @removed, $child;
    } else {
      push @children, $child;
    }
  }
  $self->[CHILDREN] = \@children;
  return _coll(@removed);
}   

sub as_HTML {
  my ($self, $arg) = @_;
  $arg ||= {};
  my $str = "<$self->[TAG]";
  for ( sort grep { !/^-/ } keys %{$self->[ATTR]}, qw(id class) ) {
    my $val = $self->attr($_);
    $str .= qq{ $_="} . $self->attr($_) . qq{"}
      if defined $val and ($_ ne 'class' or length($val));
  }
#  $str .= qq{ id="$self->[ID]"} if $self->[ID];
#  $str .= qq{ class="} . $self->class . qq{"} if @{$self->classes};
#  $str .= qq{ $_="$self->[ATTR]->{$_}"}
#    for sort grep { !/^-/ } keys %{$self->[ATTR]};
  if ($DEFAULT_CLOSED{$self->[TAG]}) {
    $str .= ' />';
  } else {
    $str .= '>' . join("", map { $_->as_HTML } $self->children);
    $str .= "</$self->[TAG]>";
  }
  $str .= "\n" if $DEFAULT_NEWLINE{$self->[TAG]};
  return $str;
}

#sub as_string {
#  my ($self) = @_;
#  my $str = $self->tag;
#  $str .= qq{ id="} . $self->id . q{"} if $self->id;
#  $str .= qq{ class="} . $self->class . q{"} if $self->classes;
#  return "<$str>";
#}

package HTML::Element::Tiny::Text;

BEGIN { use vars qw(@ISA); @ISA = 'HTML::Element::Tiny' }

sub children { return () } 
sub _all     { return $_[0] }
sub tag      { '-text' }
sub parent   { return () }
sub id       { return }
sub class    { return }
sub classes  { return () }
sub attr     { return ref $_[1] ? $_[0] : (); }
sub clone    { return $_[0] }
sub append   { die "unimplemented" }
sub remove_child { die "unimplemented" }

my %ENT_MAP = (
  '&' => '&amp;',
  '<' => '&lt;',
  '>' => '&gt;',
  '"' => '&quot;',
  "'" => '&apos;',
);

sub as_HTML {
  return HTML::Entities::encode_entities(${$_[0]})
    if $HTML::Element::Tiny::HAS_HTML_ENTITIES;
  my $str = ${$_[0]};
  $str =~ s/([<>&'"])/$ENT_MAP{$1}/eg;
  return $str;
}

package HTML::Element::Tiny::Iterator;

sub next { $_[0]->() }

package HTML::Element::Tiny::Collection;

sub new {
  my $class = shift;
  my $self = bless [ @_ ] => ref $class || $class;
  return wantarray ? @$self : $self;
}

sub size { scalar @{$_[0]} }

sub each {
  my ($self, $code) = @_;
  for (@$self) { $code->() }
  return $self;
}

sub one {
  my $self = shift;
  Carp::croak "not exactly one element (@$self)" unless @$self == 1;
  return $self->[0];
}

sub all { @{$_[0]} }

sub map {
  my ($self, $code) = @_;
  return map { $code->() } @$self;
}

sub filter {
  my ($self, $spec) = @_;
  return $self->new(grep { $_->_match($spec) } @$self);
}

BEGIN { *grep = \&filter }

sub not {
  my ($self, $spec) = @_;
  return $self->new(grep { ! $_->_match($spec) } @$self);
}

sub attr {
  my ($self, $arg) = @_;
  return ref $arg
    ? $self->each(sub { $_->attr($arg) })
    : $self->map(sub { grep { defined && length } $_->attr($arg) })
  ;
}

1;
__END__

=head1 NAME

HTML::Element::Tiny - lightweight DOM-like elements

=head1 VERSION

Version 0.006

=head1 SYNOPSIS

  use HTML::Element::Tiny;
  my $tree = HTML::Element::Tiny->new(
    [ div => { id => "stuff" },
      "some text",
      [ div => "another div inside that one" ],
      "some more text"
    ]
  );

  my $elems = $tree->find({ tag => 'div' });

=head1 DESCRIPTION

HTML::Element::Tiny is a simple module for dealing with trees of HTML elements,
including traversing them and manipulating the tree structure and individual
element attributes, and then for generating HTML.

Though it lives under HTML::, there's no reason that you couldn't use this for
processing arbitrary XML, maybe with L<XML::Tiny|XML::Tiny> in front of it.

=head1 CAVEATS

This module does not make very many efforts to check its input as far as HTML
validation goes.  For example, nothing will stop you from having a tree with a
repeated C<id> attribute; this will cause you grief if you try to find by that
id, since you will only ever get the first such element, and you won't get an
error.

=head1 ACCESSORS

=head2 parent

The parent of this element, or undef if it is a root.

=head2 children

A list of the children of this element.

=head2 tag

  print $elem->tag; # "div"

The HTML tag for this element.

=head2 id

=head2 class

  print $elem->id; # "mylist"

  print $elem->class # "menu alert"

Shortcuts for commonly-used attributes.  These are not mutators.

=head2 classes

  my @classes = $elem->classes;

Where C<< ->class >> returns all classes joined with a space, this method
returns a list of classnames.

=head2 attr

  print $elem->attr('href'); # "http://...something.../"

  $elem->attr({ src => "http://somewhere.com" });

Get or set attributes of an element.

With a single scalar, return the requested attribute.

With a hashref, set attributes based on keys and values of that hashref.

=head1 METHODS

=head2 new

  my $elem = HTML::Element::Tiny->new([ ... ]);

Build a new element based on the given arrayref, which is the same format
expected by L<<< C<< HTML::Element->new_from_lol >>|HTML::Element/new_from_lol >>>,
namely:

  [ <tag>, <optional \%attributes>, <strings or more arrayrefs> ]

Any children (elements past the tag and optional attributes) will recursively
have C<new> called on them as well.

=head2 clone

  my $clone = $elem->clone(\%attributes);

Return a clone of this element and its descendents, deleting the clone's parent
(making it a root of its own tree) and adding any extra attributes specified.

Clone (0.28 or later) will be used, if installed.  This is about twice as fast
as the internal manual clone that HTML::Element::Tiny does.

=head2 iter

  my $iter = $elem->iter;

Returns an iterator for this node and all its descendents.  See L</ITERATORS>.

=head2 all

  my $elems = $elem->all;

Returns a collection of this node and all its descendents.  See
L</COLLECTIONS>.

=head2 find

=head2 find_one

=head2 find_iter

  my $elems = $tree->find(\%arg);

  my $elem = $tree->find_one(\%arg); # or die

  my $iter = $tree->find_iter(\%arg);

These are the main traversal methods of HTML::Element::Tiny.  Each takes a
hashref argument which is interpreted as attributes to be matched, and searches
the invocant element and all its descendents.  The special C<-tag> attribute
matches the element tag.  Use an empty string to indicate that an attribute
should not be present.

For example:

  { -tag => 'div', class => 'alert', id => "" }

will match divs that have a class of 'alert' (and possibly others), but not
divs with an id attribute.

C<find> returns a collection of matched elements.  In list context, this is
simply a list of the elements.  See L</COLLECTIONS>.

C<find_one> either returns a single element or dies, complaining that it
couldn't find any elements or it found too many.

C<find_iter> returns an iterator of matched elements.  See L</ITERATORS>.

=head2 prepend

=head2 append

  $elem->append(@elements, @text, @lists_of_lists);

Add all arguments to the element's list of children, either at the beginning or
at the end.

Strings and arrayrefs will be passed through C<new> first.  Objects will be
cloned if they already have a parent or simply attached if they do not.

=head2 remove_child

  $elem->remove_child(@elements, @indices);

Remove all listed children from the element.  Arguments may either be element
objects or indices (starting at 0).

Returns a collection of removed children.

=head2 as_HTML

  print $tree->as_HTML;

Return the element and its descendents as HTML.  If
L<HTML::Entities|HTML::Entities> is installed, it will be used to escape any
text nodes; otherwise, minimal entity escaping is done (C<< &<>"' >>).

=head1 ITERATORS

Several methods in this class return iterators.  These iterators return
elements as you call C<< ->next >> on them.  They have no other methods and
return C<undef> when exhausted.

=head1 COLLECTIONS

Several methods in this class return element collections.  These objects
represent aggregates, often a sort of 'current selection'.  Most of their
methods are chainable -- each method notes whether it returns a collection
(either the same object or a clone) or some other value.  Any method that
returns a collection only does so in scalar context.  In list context, those
methods return a normal list of elements.

=head2 each

  my %seen;
  $elems->each(sub { $seen{$_->tag}++ });

Call the passed-in coderef once for each element.  The current element is
available as C<$_>.

Returns: collection, unchanged except for whatever your sub does (may change
elements in-place)

=head2 filter

=head2 grep

=head2 not

  my $elems_without_id = $elems->filter({ id => "" });

  my $elems_with_id = $elems->not({ id => "" });

Using the same syntax as L</find>, select only matching elements.

C<grep> is a synonym for C<filter>.

C<not> selects only elements that do not match.

Returns: new collection

=head2 attr

  $elems->attr({ class => "bogus" });
  my @ids = $elems->attr('id');

Get or set element attributes.

With a hashref, this is a shortcut for C<each> and C<< $_->attr(\%arg) >>.

With a scalar, this is a shortcut for C<map>, with the added advantage that it
removes all empty values.

Returns: same collection OR list of values

=head2 one

  my $e = $elems->one;

Return a single element, verifying that the collection does contain exactly one
element.

Return: element

=head2 all

  my @elems = $elems->all;

Return every element in the collection, as a normal Perl list.

Return: list of elements (not collection)

=head2 map

  my @frobbed = $elems->map(sub { Frobber->frob($_) });

Shortcut for C<< map { $code->() } $elems->all >>.

Return: list of values

=head2 size

  my $size = $elems->size;

Return: number of elements in collection

=head1 EXTENDING

It is possible to change the classes into which new elements are blessed.  When
C<new> is called, it looks for a C<%TAG_CLASS> in the invocant's package.  If
present, it will use the tag name as a key and expect a class as the value.
Thus:

  package My::Element;
  use base 'HTML::Element::Tiny';
  our %TAG_CLASS = (img => "My::Element::Image");
  ... # elsewhere
  my $img = My::Element->new([ img => { src => "http://..." } ]);
  # $img isa My::Element::Image

Some keys and values in this hash are magical.  Classes that start with '-'
have it replaced with C<$class::>, e.g.

  our %TAG_CLASS = (img => '-Image');

If there is a C<-base> key, it is used instead of the class name when doing
this sort of expansion.

To change the default element class, add a C<-default> key.

A class that used all these options might have a C<%TAG_CLASS> that looked like
this:

  our %TAG_CLASS = (
    -default => 'My::Element::Base',
    -base    => 'My::Element',
    img      => '-Image',
    map      => '-Map',
  );

The default is to use the invocant's package for both C<-default> and C<-base>.

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-element-tiny at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Element-Tiny>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Element::Tiny

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Element-Tiny>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Element-Tiny>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Element-Tiny>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Element-Tiny>

=back

=head1 ACKNOWLEDGEMENTS

A lot of the HTML generation is either directly from or inspired by Andy
Armstrong's excellent L<HTML::Tiny|HTML::Tiny> module.

The concept of element collections is shamelessly lifted from jQuery.
http://jquery.com/

=head1 COPYRIGHT & LICENSE

Copyright 2007 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::Element::Tiny

package List::oo;
$VERSION = v0.2.1;

use warnings;
use strict;

use Carp;

use List::oo::Extras;

require Exporter;
*{import} = \&Exporter::import;

our @EXPORT_OK = qw(
  L
  Split
  F
  $a
  $b
  );

# XXX now I need tags

=encoding utf8

=head1 NAME

List::oo - object interface to list (array) methods

=head1 SYNOPSIS

Connecting multiple list I<functions> together "reads" from right to
left (starting with the data input way over on the right.)

This module provides a chainable method interface to array objects,
which can be a bit more readable when multiple operations are involved.

This

  print join(' ', map({"|$_|"} qw(a b c))), "\n";

becomes:

  use List::oo qw(L);
  print L(qw(a b c))->map(sub {"|$_|"})->join(' '), "\n";

There is definitely some cost of execution speed.  This is just an
experiment.  Comments and suggestions welcome.

=cut

=head1 Constructors

=head2 new

  $l = List::oo->new(@array);

=cut

sub new {
  my $caller = CORE::shift;
  my $class = ref($caller) || $caller;
  my $self = [@_];
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 L

  $l = L(@array);

=cut

sub L {
  return(List::oo->new(@_));
} # end subroutine L definition
########################################################################

=head1 Strange Constructors

This is only here because you so frequently need to start with a string
op and L(split(...)) is ugly.

Aside:  I'm not sure I really like this as an interface point.  The need
to use qr// is at least a little annoying.

=head2 Split

  my $l = Split(qr/\s+/, $string);

=cut

sub Split {
  my ($regex, $string) = @_;
  ## warn "$regex, $string\n";
  UNIVERSAL::isa($regex, 'Regexp') or
    croak("First argument to Split must be a regular expression");
  return(List::oo->new(split($regex, $string)));
} # end subroutine Split definition
########################################################################

=head1 Convenience Functions

=head2 F

Declare a subroutine.

  F{...};

See also L<lambda>, which lets you use C<λ{}> instead.

=over

=item About the C<sub {...}> syntax

Sadly, perl5 does not allow prototypes on methods.  Thus, we cannot use
the undecorated block syntax as with

  map({...} @list);

Rather, you must use the explicit C<sub {...}> syntax

  $l->map(sub {...});

Or, use the C<F{}> or C<λ{}> shortcuts.

  use List::oo qw(F);
  ...
  $l->map(F{...});

With L<lambda>

  use lambda;
  ...
  $l->map(λ{...});

(If the above doesn't render as the greek character lambda, your pod
viewer is not playing nice.)

=back

=cut

sub F (&) {
  my $sub = CORE::shift(@_);
  @_ and croak;
  UNIVERSAL::isa($sub, 'CODE') and return($sub);
  eval($sub->isa('List::oo')) and croak 'not a method';
  croak('why bother');
} # end subroutine F definition
########################################################################

=head1 List Methods

These methods are mostly analogous to the perl builtins.  Where the
builtin would return a list, we return a List::oo object.  Where the
builtin returns a scalar or some data which was not the primary list
(e.g. C<push>, C<pop>, C<splice>, etc.), you'll find some iI<foo>()
methods (the 'i' prefix is for 'inline'.)

=head2 grep

  $l = $l->grep(sub {...});

=cut

sub grep {
  my $self = CORE::shift;
  my $sub = CORE::shift;
  return($self->new(CORE::grep({$sub->($_)} @$self)));
} # end subroutine grep definition
########################################################################

=head2 map

  $l = $l->map(sub {...});

=cut

sub map {
  my $self = CORE::shift;
  my $sub = CORE::shift;
  return($self->new(CORE::map({$sub->($_)} @$self)));
} # end subroutine map definition
########################################################################

=head2 reverse

  $l = $l->reverse;

=cut

sub reverse {
  my $self = CORE::shift;
  return($self->new(CORE::reverse(@$self)));
} # end subroutine reverse definition
########################################################################

=head2 dice

Does things that can't be done with map.

  $l2 = $l->dice(sub {my @a = @_; ... return(@a);});

Feeds @$l into sub, which should return a perl list.  Puts the results
in a new List::oo object.

The purpose is simply to allow you to write an unbroken chain when you
need to feed the entire list through some function which doesn't operate
per-element.

Without this, you would have to break the chain of thought

  L(that_function($l->map(\&fx)->l))->map(\&fy);

With dice, simply insert it where it is needed.

  $l->map(\&fx)->dice(sub {that_function(@_)})->map(\&fy);

Note that in contrast to map() and grep() methods, dice() does not
define the $_ variable.

What sort of functions need the whole list?  Say you want to reverse
the front and back half of a list, or maybe break a list of 20 items
into 5 references of 4 items each.  See the tests for examples.

=cut

sub dice {
  my $self = CORE::shift;
  my $sub = CORE::shift;
  return($self->new($sub->(@$self)));
} # end subroutine dice definition
########################################################################

=head2 sort

A lot like CORE::sort.

  $l->sort;

  $l->sort(sub {$a <=> $b});

Unfortunately, we don't get the sort C<$a>/C<$b> package variable magic.
So, I set your package's $a and $b just like sort would.  This means you
might get "used only once" warnings, but you can silence these with:

  use List::oo qw($a $b);

The C<$a> and C<$b> imports have no other effect.

=cut

sub sort {
  my $self = CORE::shift;
  my $sub = CORE::shift;
  # XXX should these be in-place methods or not?
  if( $sub) {
    my $caller = caller;
    my ($ca, $cb) = map({eval('\\$'.$caller.'::'.$_)} qw(a b));
    return($self->new(CORE::sort(
      # sort sets my package vars, so I have to set them into
      # caller's here to make this work
      {($$ca, $$cb)=($a,$b); $sub->();}
      @$self))
    );
    # THE OTHER OPTION {{{
    # my @list = eval("package $caller; CORE::sort(\$sub \@\$self)");
    # return($self->new(@list));
    # }}}
  }
  else {
    return($self->new(CORE::sort(@$self)));
  }
} # end subroutine sort definition
########################################################################

=head2 splice

Splices into @$l and returns the removed elements (or last element in
scalar context) ala CORE::splice.

  $l->splice($offset, $length, @list);

With no replacement:

  $l->splice($offset, $length);

Remove everything from $offset onward

  $l->splice($offset);

Empties the list

  $l->splice;

=cut

sub splice {
  my $self = CORE::shift;
  if(@_ >= 3) {
    my ($o, $l) = (CORE::shift(@_), CORE::shift(@_));
    return CORE::splice(@$self, $o, $l, @_);
  }
  elsif(@_ == 2) {
    return CORE::splice(@$self, $_[0], $_[1]);
  }
  elsif(@_ == 1) {
    return CORE::splice(@$self, $_[0]);
  }
  else {
    return CORE::splice(@$self);
  }
} # end subroutine splice definition
########################################################################

=head1 Head and Tail Methods

=head2 push

Returns the new length of the list.

  $l->push(@stuff);

=cut

sub push {
  my $self = CORE::shift;
  CORE::push(@$self, @_);
} # end subroutine push definition
########################################################################

=head2 pop

Removes and returns the last item.

  $l->pop;

=cut

sub pop {
  my $self = shift;
  pop(@$self);
} # end subroutine pop definition
########################################################################

=head2 shift

Removes and returns the first item.

  $l->shift;

=cut

*{List::oo::shift} = sub { # declaring like that makes CORE::shift() not needed
  my $self = CORE::shift;
  CORE::shift(@$self);
}; # end subroutine shift definition
########################################################################

=head2 unshift

Prepends @stuff to @$l and returns the new length of @$l.

  $l->unshift(@stuff);

=cut

sub unshift {
  my $self = shift;
  CORE::unshift(@$self, @_);
} # end subroutine unshift definition
########################################################################

=head1 Inlined Methods

If you want to keep chaining calls together (and don't need to retrieve
the pop/shift/splice data.)

=head2 ipush

  $l->map(sub {...})->ipush($val)->map(sub {...});

=head2 ipop

  $l->map(sub {...})->ipop->map(sub {...});

=head2 ishift

  $l->map(sub {...})->ishift->map(sub {...});

=head2 iunshift

  $l->map(sub {...})->iunshift($val)->map(sub {...});

=head2 isplice

  $l->map(sub {...})->isplice($offset, ...)->map(sub {...});

=cut

foreach my $method (qw(push pop shift unshift splice)) {
  no strict 'refs';
  *{__PACKAGE__ . "::i$method"} = sub {
    my $self = CORE::shift;
    $self->$method(@_);
    return($self);
  };
}

=head2 wrap

Add new values to the start and end.

  $l = $l->wrap($head,$tail);

Is just:

  $l->iunshift($head)->ipush($tail);

=cut

sub wrap {
  my $self = CORE::shift;
  my ($head, $tail) = @_;
  $self->unshift($head);
  $self->push($tail);
  return($self);
} # end subroutine wrap definition
########################################################################

=head1 Additions to List::MoreUtils

The lack of prototypes means I can't do everything that List::MoreUtils
does in exactly the same way.  I've chosen to make the bindings to
multi-list methods take only single lists and added mI<foo>() methods
here.

=head2 mmesh

Meshes @$l, @a, @b, @c, ...

  my $l = $l->mmesh(\@a, \@b, \@c, ...);

=cut

sub mmesh {
  my $self = shift;
  my (@lists) = @_;
  return($self->new(&List::MoreUtils::mesh($self, @lists)));
} # end subroutine mmesh definition
########################################################################

=head2 meach_array

Just the binding to List::MoreUtils::each_arrayref;

  my $iterator = $l->meach_array(\@a, \@b, \@c);

=cut

sub meach_array {
  goto &List::MoreUtils::each_arrayref;
} # end subroutine meach_array definition
########################################################################

=head1 Give Me Back My List

You can wrap the call chain in @{} or use one of the following methods.

=head2 flatten

If you really like to type.

  @list = $l->flatten;

=head2 l

The l is pretty flat and is the lowercase (less special) version of our
terse constructor L().

  @list = $l->l;

=cut

sub flatten {
  my $self = CORE::shift;
  return(@$self);
} # end subroutine l definition
########################################################################
sub l {shift->flatten;}

=head1 Scalar Result Methods

These only work at the end of a chain.

=head2 join

  $string = $l->join("\n");

=cut

sub join {
  my $self = CORE::shift;
  my $char = CORE::shift;
  return(CORE::join($char, @$self));
} # end subroutine join definition
########################################################################

=head2 length

Length of the list.

  $l->length;

=cut

sub length {
  my $self = CORE::shift;
  return(scalar(@$self));
} # end subroutine length definition
########################################################################

=head1 List::Util / List::MoreUtils

The following method documentation is autogenerated along with the
wrappers of functions from List::Util and List::MoreUtils.  The
supported usage is shown (in some cases, these methods only support a
subset of the function usage (due to the lack of method prototype
support.)

The clusters of sigils (e.g. C<l=&l>) are included as a shorthand
reference.  These sigils are what drive the code generation (see the
source of List::oo::Extras and the build_extras.pl tool in the source
repository for the dirty details.)  The sigil on the left of the '='
represents the return value, the sigils on the right of the '='
represent what is passed to the wrapped function.

  l - a List::oo object (the $self when found on the right)
  L - an array of List::oo objects
  $ - a scalar
  @ - an array
  & - a subroutine reference (λ)

See List::Util and List::MoreUtils for more info.

INSERT_AUTODOC (if you find this in the .pod file, something went wrong)

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=over

=item Thanks to

Jim Keenan for contributions to the test suite.

=back

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2006-2007 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

  EO::Array

=cut

# if 'no Carp;' would work...
delete($List::oo::{$_}) for(qw(carp croak confess));

# these aren't methods either
#delete($List::oo::{$_}) for(qw(L F));

1;
# vim:ts=2:sw=2:et:sta:encoding=utf8

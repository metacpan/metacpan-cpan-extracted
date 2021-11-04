package FindApp::Utils::Package::Object;

use strict;
use warnings;
use v5.10;

use FindApp::Utils::Carp;
use FindApp::Utils::Assert qw(:all);
use FindApp::Utils::Syntax qw(:all);
use List::Util             qw(max);
use Scalar::Util qw(
    blessed
    looks_like_number
    reftype
);

sub selfhere {
    my $self = shift;
    my $here = shift || 1;
    looks_like_number($here) || subcroak_N(2, "'$here' does not look like a number");
    $here = ($here <=> @$self) * @$self if abs($here) > @$self; # limit magnitude, keep sign
    return ($self, $here);
}

use namespace::clean;

sub   PACKAGE  ( ;$ ) ;
sub UNPACKAGE  (  _ ) ;

use  Exporter "import";
our @EXPORT    = <{,UN}PACKAGE>;
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use FindApp::Utils::Objects <op_{,not}equals>;

use overload map { $_ => "op_$_" } <cmp eq ne>;
use overload reverse (
   unbless      => qw( ""  ),
   length       => qw( 0+  ),
   op_equals    => qw( ==  ),
   op_notequals => qw( !=  ),
   op_spaceship => qw( <=> ),  # now with 👽  wormholes!
   op_plus      => qw(  +  ),
   op_minus     => qw(  -  ),
   op_neg       => qw( neg ),
);

# Exported constructor via string, defaults to caller's package
# and imposes scalar context on its argument so you can pass
# it PACKAGE(caller) more easily.  You can call it as &PACKAGE
# to circumvent the prototype so you can pass multiple bits
# to the constructor, as in
#       &PACKAGE(map {ucfirst} <three blind mice>)
# To get a Three::Blind::Mice object back without being forced to type
#    new FindApp::Utils::Package::Object map {ucfirst} <three blind mice>
sub PACKAGE(;$) {
  __PACKAGE__ -> new(@_ ? @_ : scalar caller);
}

# And this one goes the other way, mostly for mapping.
# This is just the functional version of the method,
# with a builtin default argument of $_ for convenience.
sub UNPACKAGE(_) {
    my($package)  = @_;
    my $unpackage = $package->unbless;
    if (defined wantarray) { return  $unpackage }
    else                   { $_[0] = $unpackage }
}

# Constructor via string, defaults to caller's package.
sub new {
    my $invocant = shift;
    my $class    = blessed($invocant) || $invocant;
    return $invocant->new(join "::", @_) if @_ > 1;
    #my $path = (@_ ? shift : caller) || subcroak "no path";
    my $path = @_ ? shift : "main"; # subcroak "no path";
       $path = blessed($path) if blessed($path);
    my @self = grep { length } split /(?:::|')/, $path;
    shift  @self while @self > 1 && $self[0] eq "main";
    bless \@self, $class;
}

################################################################

sub op_eq($$$) :method {
    my($this, $that, $swapped) = @_;
    use locale;
    return "$this" eq "$that"
}

sub op_ne($$$) :method { !&op_eq }

sub op_cmp($$$) :method {
    my($this, $that, $swapped) = @_;
    no warnings "uninitialized";
    no overloading;
    for my $i (0 .. max $#$this, $#$that) {
        return $this->[$i] cmp $that->[$i]
        unless $this->[$i]  eq $that->[$i];
    }
    return 0;
}

sub op_spaceship($$$) :method {
    my($this, $that, $swapped) = @_;
    no overloading;
    return @$this <=> @$that
    unless @$this  == @$that;
    goto \&op_cmp; # 👽  spaceships are permitted to use wormholes for speed
}

sub op_plus($$$) :method {
    my($this, $that, $swapped) = @_;
    if (!blessed($that) && looks_like_number($that)) {
        return $this->length + $that;
    }
    unless($swapped) {
        return $this->add($that);
    }
    $that = PACKAGE($that) unless blessed $that;
    return $that->add($this);
}

sub op_minus($$$) :method {
    my($this, $that, $swapped) = @_;
    return $this if $that == 0;
    return $this->super($that);
}

sub op_neg($) :method {
    my($this) = @_;
    return $this->left;
}

################################################################

# this is useful in parallel situations (see subpackage, etc)
sub self :method {
    my $self = shift;
    @_ == 0 || subcroak "no arguments allowed";
    return $self;
}

*object = \&self;

sub class :method {
    my $self = shift;
    @_ == 0 || subcroak "no arguments allowed";
    return blessed($self) || $self;
}

# Deconstructor to string
sub unbless :method {
    my $self = shift;
    join("::", @$self) || "main";
}

*as_string = \&unbless;

# Deconstructor to array
sub split() :method {
    my $self = shift;
    @_ == 0 || subcroak "no arguments allowed";
    @$self ? @$self : "main";
}
*as_list = \&split;

# In case I someday change the implementation.
sub aref() :method {
    my $self = shift;
    @_ == 0 || subcroak "no arguments allowed";
    return [ @$self ];
}

sub length() :method {
    my $self = shift;
    0 + @$self;
}

# The leftmost N portions, defaulting to 1 and maxing at length.
sub left(;$) :method {
    my($self, $here) = &selfhere;
    @_ == 0 || subcroak "need one argument or none";
    return $self->new("main") if $here == -@$self;
    my @self = @$self;
    splice @self, $here;
    return $self->new(@self);
}

sub left_but(;$) :method {
    my($self, $here) = &selfhere;
    @_ == 0 || subcroak "need one argument or none";
    $self->left(-$here);
}

# The rightmost N portions, defaulting to 1 and maxing at length.
sub right(;$) :method {
    my($self, $here) = &selfhere;
    @_ == 0 || subcroak "need one argument or none";
    return $self->new("main") if $here == -@$self;
    my @self = @$self;
    return $self->new(splice @self, -$here);
}

sub right_but(;$) :method {
    my($self, $here) = &selfhere;
    @_ == 0 || subcroak "need one argument or none";
    $self->right(-$here);
}

# The N-times super-package, defaulting to 1.
*super = \&left_but;  # even faster than goto :)

# Cuts the old object in two at the given position. By default
# splits at 1, so returns the dirname/superclass portion as the
# left and the basename/class portion as the right.
sub bisect(;$) : method {
    my($self, $here) = &selfhere;
    @_ == 0 || subcroak "need one argument or none";
    my @self = @$self;
    my @right = splice @self, -$here;
    my $pair = [
        $self->new(@self  ? @self  : "main"),
        $self->new(@right ? @right : "main"),
    ];
    return wantarray ? @$pair : $pair;
}

sub left_and_right(;$) : method { &bisect }

sub right_and_left(;$) : method {
    my($self, $here) = &selfhere;
    @_ == 0 || subcroak "need one argument or none";
    $self->bisect(-$here);
}

# Construct subpackages, one for each argument.
# Must be called in list context if multiple args.
sub add(@) :method {
    my($self, @new) = @_;
    my @self = @$self;
    @new > 0  || subcroak "need list of subpackages to generate";
    push @self, map { ref && reftype($_) eq "ARRAY" ? @$_ : $_ } @new;
    $self->new(@self);
}

sub sib(@) :method {
    my($self) = shift;
    @_ > 0  || subcroak "need sibling package";
    $self->super->add(@_);
}

sub add_all(@) {
    my($self, @ends) = @_;
    @ends > 0                  || subcroak "need list of subpackages to generate";
    wantarray || @ends == 1    || subcroak "expected list context when generating multiple subpackages";
    my @packs = map { $self->add($_) } @ends;
    return wantarray ? @packs : $packs[0];
}

sub add_all_unblessed {
    my @pack_obs = &add_all;
    map { UNPACKAGE } @pack_obs;
}

sub span($$) :method {
    @_ == 3                     || subcroak "need 2 ordinals to span, not ".(@_-1)." of them";
    my($self, $start) = &selfhere;
    unshift @_, $self;
    my(undef, $end) = &selfhere;

    # forgive them
    if ($start < 0 && $end < 0 && $end < $start) {
        ($start,  $end)
                =
        ($end,    $start) ;
    }

    if ($start > 0 && $end < 0) {

    }

    $end >= $start              || subcroak "end argument $end should not be less than start argument $start";
    $end  * $start > 0          || subcroak "span arguments $start and $end should have same sign";
    if ($start > 0) { for ($start, $end) { $_-- } }
    $self->new( @$self [ $start .. $end ] );
}

sub slice(@) :method {
    @_ > 1                      || subcroak "need one or more arguments";
    my($self, @here) = @_;
    for my $here (@here) {
        (undef, $here) = selfhere($self, $here);
        $here-- if $here > 0;
    }
    $self->new(@$self[@here]);
}

sub snip($;$) :method {
    @_ == 2 || @_ == 3          || subcroak "need either one or two arguments";
    my($self, $here) = &selfhere;
    $here-- if $here > 0;
    my @self = @$self;
    if (my $end = shift) {
        my $count = $end - $here;
        $count += @self if $count < 0;
        #warn "splice(@self, $here, $count);";
        splice(@self, $here, $count);
    } else {
        splice(@self, $here);
    }
    $self->new(@self);
}

sub splice($;$@) :method {
    @_ >= 2 || subcroak "need at least one argument";
    my($self, $here) = &selfhere;
    $here-- if $here > 0;
    my @self = @$self;
    if (my($count, @new) = @_) {
        splice(@self, $here, $count, @new);
    } else {
        splice(@self, $here);
    }
    $self->new(@self);
}


# Why you would ever want to do this, I have no idea.
sub reverse($) :method {
    my $self = shift;
    @_ == 0 || subcroak "no arguments allowed";
    $self->new(CORE::reverse $self->split);
}

# Returns string, not object.
sub join($) :method {
    @_ == 2                     || subcroak "need one arg, not " . (@_-1);
    my $self = shift;
    my $separator = shift;
    return CORE::join($separator, $self->split);
}

sub map(&) :method {
    @_ == 2                     || subcroak "need one arg, not " . (@_-1);
    my($self, $code) = @_;
    $self->new(CORE::map(&$code, $self->split));
}

# Returns new object(s)? and leaves original untouched.
sub grep(&) :method {
    @_ == 2                     || subcroak "need one arg, not " . (@_-1);
    my($self, $code) = @_;
    CORE::grep(&$code, $self->split);
}

# Returns string, not object.
sub abbreviate(;$) :method {
    @_ <= 2                     || subcroak "need either one argument or none, not " . (@_-1) . " of them";
    my $self = shift;
    my $here = shift || 1;
    my($left, $right) = $self->bisect($here);
    $left->map(sub { /^(\p{Lu})/ ? lc($1) : $_ })->add($right)->join(":");
}

# Returns string, not object.
sub pmpath($) :method { shift->join("/").".pm" }

# Returns hash ref, not object.
sub stash($) {
    my $self = shift;
    @_ == 0 || subcroak "no arguments allowed";
    no strict "refs";
    return \%{$self."::"};
}

1;

=encoding utf8

=head1 NAME

FindApp::Utils::Package::Object - FIXME

=head1 SYNOPSIS

 use FindApp::Utils::Package::Object;

=head1 DESCRIPTION

=head2 Public Methods

=head3 C<abbreviate>

Returns a string where all package elements but the last two
have been abbreviated to a single lowercase letter.  Used for
debugging output when the FINDAPP_DEBUG_SHORTEN environment variable is true.

    $short = PACKAGE("FindApp::Utils::Package::Object::abbreviate");
    # $short now f:u:p:Object::abbreviate

=head3 C<< add(I<LIST>) >>

Returns a new object with the given arguments added as further components.

    $start = PACKAGE("Three");
    $full  = $start->add("Blind", "Mice");
    # $full now Three::Blind::Mice

=head3 C<< I<OBJ_LIST> = $obj->add_all(I<LIST>) >>

Returns a list of new objects, each with the original plus one element
in the argument list appended.

    $pkg = PACKAGE("Spring::Field");
    @pkgs = $pkg->add_all("Ohio", "Iowa", "Maine");
    # Spring::Field::Ohio, Spring::Field::Iowa, Spring::Field::Maine


=head3 C<< I<STR_LIST> = $obj->add_all_unblessed(I<LIST>) >>

Like C<add_all> but returning strings not objects.

=head3 aref

Returns a reference to a copy of the object's package components.
Does not allow direct access to the original.

=head3 as_list

Returns a copy of the object's package components as a list.
Does not allow direct access to the original.

This is actually as alias for I<split>.

=head3 as_string

Returns a string of the object's package components joined with C<::>.

This is actually as alias for I<unbless>.

=head3 bisect I<ORDINAL>

Return two new objects which represent the original snipped at the
given I<ORDINAL> position.  The I<ORDINAL> may be either positive
or negative, operating symmetrically.

For a positive I<ORDINAL>, count off starting from the B<right> end and then snip,
putting everything to the left of however far you got into the left
object returned and putting everything past where you got to in the
right object returned.

    ($left, $right) = PACKAGE("A::B::C::D::E::F")->bisect(2);
    # $left  is A::B::C::D
    # $right is E::F

    ($left, $right) = PACKAGE("A::B::C::D::E::F")->bisect(4);
    # $left  is A::B
    # $right is C::D::E::F

For a negative I<ORDINAL>, count off starting from the B<left> end and
then snip, B<still> putting everything to the left of however far you
got into the left object returned and putting everything past where you
got to in the right object returned.

    ($left, $right) = PACKAGE("A::B::C::D::E::F")->bisect(-2);
    # $left  is A::B
    # $right is C::D::E::F

    ($left, $right) = PACKAGE("A::B::C::D::E::F")->bisect(-2);
    # $left  is A::B::C::D
    # $right is E::F

Therefore the magnitude of a positive I<ORDINAL> represents how many
elements are returned in the right object, while the magnitude of a
negative I<ORDINAL> represents how many elements are returned in the
left object. If you find this hard to remember or keep straight,

=head3 class

Returns the invocant class.

=head3 grep I<CODE_REF>

Returns a list of package components for which the code reference
expression tests true on as they were each set to C<$_> in succession.

    say for PACKAGE("Red::Riding::Hood")->grep(sub{/^R/});
  # Red
  # Riding

=head3 join I<STRING>

Returns a string with the package elements connected by its argument.

    say PACKAGE("Red::Riding::Hood")->join("!")
    # Red!Riding!Hood

=head3 left I<ORDINAL>

Returns a new object that has the leftmost I<ORDINAL> elements in it.

    $head = PACKAGE("A::B::C::D::E::F")->left(2);
    # $head is A::B

If a negative index is supplied, all B<but> that many
right elements are returned.

    $tail = PACKAGE("A::B::C::D::E::F")->left(-2);
    # $tail is A::B::C::D

This method have been called I<first> or I<top> or I<head> or even
I<pull> or I<unshift>, but I<left> seemed to be the least confusing,
especially once negatives are included.

=head3 left_and_right I<ORDINAL>

Returns two objects representing the left and right parts of the original.

When I<ORDINAL> is positive, it specifies how many elements will be in
the right return object.

When I<ORDINAL> is negative, its magnitude
specifies how many elements will be in the left return object.

    ($left, $right) = PACKAGE("A::B::C::D::E::F")->left_and_right(2);
    # $left  is A::B::C::D
    # $right is E::F

    ($left, $right) = PACKAGE("A::B::C::D::E::F")->left_and_right(-2);
    # $left  is A::B
    # $right is C::D::E::F

(Same as C<bisect>, but easier to remember.)

=head3 left_but I<ORDINAL>

Returns a new object that has all B<but> the last I<ORDINAL> elements
in it.  So here you get all left bits but for the last two of them:

    $front = PACKAGE("A::B::C::D::E::F")->left_but(2);
    # $front is A::B::C::D

This method exists so you don't have to remember negatives; it just
calls I<left> with the sign of its argument flipped.  Negatives
therefore work symmetrically:

    $front = PACKAGE("A::B::C::D::E::F")->left_but(-2);
    # $front is A::B


Negative ordinals mean to keep only that many rather than to discard that many:

    $front = PACKAGE("A::B::C::D::E::F")->left_but(-2);
    # $front is A::B

The C<left_but(I<N>)> method is really the C<left(I<-N>)> method so that you
don't have to think about negative ordinals.

=head3 length

Returns the number of package elements.

    $count = PACKAGE("A::B::C::D::E::F")->length;
    # $count is now 6.

This is the method used for the C<0+> operator overload.

=head3 map I<CODE_REF>

Returns a new object each of whose path components is the result
of running the given code against.

    $small = PACKAGE("A::B::C")->map(sub{lc});
    # $small is a::b::c

=head3 new I<LIST>

This is the general class constructor.

    $class = "FindApp::Utils::Package::Object";
    $ob = $class->new("A::B::C");
    # $ob now has length 3

If multiple arguments are given, they concatenate:

    $ob = $class->new("A" .. Z");
    # $ob has length 26

The single-quote version of the package separator is tolerated
on input, but the canonical form is always produced on output:

    $ob = $class->new("you", "shouldn't've");
    # $ob is now you::shouldn::t::ve

Because the package name C<FindApp::Utils::Package::Object> is so
long, the I<PACKAGE> alias for the constructor is normally used.

=head3 object

Returns the invocant.

=head3 op_cmp

This is the method used for the overloaded C<cmp> operator. It
runs a normal C<cmp> operation on each element left to right.
That means that "AB::CD::EF" will sort earlier than "ABC::DEF"
because "AB" sorts before "ABC".  The first element that differs
is what counts.

See the L<op_spaceship> method if you want it to work the other way.

In other words, it only uses the real C<cmp> operator on each element
iteratively until one fails. It does not compare the entire package as
one string.

=head3 op_eq

This is the method used for the overloaded C<eq> operator.
It compares the two strings in full using the regular C<eq>.

=head3 op_equals

This is the method used for the overloaded C<==> operator.
It is used for checking whether two objects are the same
object by comparing their reference's addresses numerically.
It returns true if their refaddrs are the same.

It's really the method of that name imported from L<FindApp::Utils::Objects>.

=head3 op_minus

This is the method used for the overloaded binary C<-> operator,
the infix one.
It is the same as calling the I<super> method with its numeric
argument, so throws away that many elements from the right and
returns a new object.

    $ob = PACKAGE("usr::bin::perl");
    print $ob - 1;
    # prints usr::bin

This is also used for derived C<-=> and C<--> operators.

=head3 op_ne

This is the method used for the overloaded C<ne> operator.
It is simply the reverse of the C<eq> operator.

=head3 op_neg

This is the method used for the overloaded unary C<-> operator,
the prefix one.  It's a quick way to get the leftmost element.

    $ob = PACKAGE("usr::bin::perl");
    print -$ob;
    # prints "usr"

=head3 op_notequals

This is the method used for the overloaded C<!=> operator.
It is used for checking whether two objects are different
objects by comparing their reference's addresses numerically.
It returns true if their refaddrs are not the same number.

It's really the method of that name imported from L<FindApp::Utils::Objects>.

=head3 op_plus

This is the method used for the overloaded binary C<+> operator.
As you might expect, it returns a new object that has the right operand
concatenated to the end of the left operand in that order.

    print PACKAGE("A::B") + PACKAGE("X::Y");
    # prints A::B::X::Y

It is not associative, since ordering matters.

=head3 op_spaceship

This is the method used for the overloaded C<< <=> >> operator.

It first compares the numbers of elements in each operand as numbers,
and only if those are the same does it then go on compare the respective
pieces as strings. That means that shorter package counts sort earlier
even if they have later letters. So all one-element packages would sort
before all two-element ones, and so on.

    PACKAGE("AB::CD::EF") <=> PACKAGE("ABC::DEF") # 1

That returns 1 because the first has three elements and the second has two.
See the L<op_cmp> method if you want it to work the other way by comparing
"AB" with "ABC".

Another way to think of it is that C<< $a <=> $b >> is that is works like

    $a->length <=> $b->length
               ||
            $a cmp $b

In other words, the real C<< <=> >> operator is used only for comparing
lengths.  If the lengths are the same, then C<cmp> operator is used one
package element at a time.

=head3 pmpath

This method converts the package object into a path sting by swapping
the double colons out for slashes and appending ".pm" to the end.
It's just there to give a name to this simple operation:

    $obj->join("/").".pm"

=head3 reverse

Returns a new object with all its elements laid out the other
direction.

    PACKAGE("AB::CD::EF")->reverse
    # produces ED::CD::AB

=head3 right I<ORDINAL>

Returns a new object that has the rightmost I<ORDINAL> elements in it.

    $tail = PACKAGE("A::B::C::D::E::F")->right(2);
    # $head is E::F

If a negative index is supplied, all B<but> that many
left elements are returned.

    $head = PACKAGE("A::B::C::D::E::F")->right(-2);
    # $tail is A::B::C::D

This method have been called I<last> or I<pop> or I<tail>.

=head3 right_and_left I<ORDINAL>

Returns two objects representing the left and right parts of the
original, in that order. When I<ORDINAL> is positive, it specifies how
many elements will be in the left return object. When I<ORDINAL> is
negative, its magnitude specifies how many elements will be in the right
return object.

    ($left, $right) = PACKAGE("A::B::C::D::E::F")->right_and_left(2);
    # $left  is A::B
    # $right is C::D::E::F

    ($left, $right) = PACKAGE("A::B::C::D::E::F")->right_and_left(-2);
    # $left  is A::B::C::D
    # $right is E::F

This method exists so you don't have to think about negative ordinals,
but it is potentially confusing because you get back the left first
and the right second even though those words occur in the opposite
order in the name of the method. Just remember that whichever word
has the number near it is how many of that you get.

=head3 right_but I<ORDINAL>

Returns a new object that has all B<but> the first I<ORDINAL> elements
in it.  So here you get all the right bits but for the first two of them:

    $back = PACKAGE("A::B::C::D::E::F")->right_but(2);
    # $back is C::D::E::F

Negative ordinals keep only that many rather than to discard that many:

    $back = PACKAGE("A::B::C::D::E::F")->right_but(-2);
    # $back is E::F

The C<right_but(I<N>)> method is really the C<right(I<-N>)> method so that you
don't have to think about negative ordinals.

=head3 self

Returns the object itself.  Dies if invoked on a class.

=head3 sib I<NAME>

Returns a new object which is the named "sibling" package of the one specified.
So for example if your package is A::B::C, then your super is A::B and represents
your parent, and if you had a sibling named J, that would be A::B::J.

    $sib = PACKAGE("A::B::C")->sib("J");
    # $sub is A::B::J

It only returns one result no matter how many arguments you supply; if
you pass more than one I<NAME>, these are each separate elements in the
one return object:

    $sib = PACKAGE("A::B::C")->sib("J","K");
    $ $sib is A::B::J::K.

=head3 slice I<INDICES>

Returns a new object selecting only those elements whose ordinals you specify
in the argument list.  Positive ordinals count from the left and negatives
ones from the right.

    $class   = "FindApp::Utils::Package::Object";
    $abc_obj = $class->new("A" .. "Z");
    # $abc_obj is A::B::C::D::E::F::G::H::I::J::K::L::M::N::O::P::Q::R::S::T::U::V::W::X::Y::Z

    print $abc_obj->slice(1,3,-3,-1);
    # prints A::C::X::Z

=head3 snip I<START>, I<END>

Returns a new object formed by joining portion to left of the I<START>
ordinal to the portion to the right of the I<END> ordinal in the original
package elements.

=head3 span I<START>, I<END>

Returns a new object consisting of a span of all the original package
elements starting with the I<START> ordinal and ending with the I<END>
ordinal.  The second argument must not be less than the first argument.

    $class   = "FindApp::Utils::Package::Object";
    $abc_obj = $class->new("A" .. "Z");
    # $abc_obj is A::B::C::D::E::F::G::H::I::J::K::L::M::N::O::P::Q::R::S::T::U::V::W::X::Y::Z

    print $abc_obj->span(1, 4);
    # prints A::B::C::D

    print $abc_obj->span(-4, -1);
    # prints W::X::Y::Z

    print $abc_obj->span(4, 8);
    # prints D::E::F::G::H

As a special dispensation for a common mistake, if both arguments
are negative but the second is greater than the first, then you
must have reversed the arguments by accident and so the method
flips them back as though you had written them correctly.

    #         means span(-4, -1)
    print $abc_obj->span(-1, -4);
    # prints W::X::Y::Z

=head3 splice I<START>, I<END>

=head3 splice I<START>

Returns a new object with everything between I<START>
and I<END> deleted.  If I<END> is omitted, everything
till the end is deleted.

=head3 split

=head3 stash

=head3 super

=head3 unbless

=head2 Exports

=over

=item PACKAGE(;$)

=item UNPACKAGE(_)

=back

=head2 Sorting

resorting the dict-sorted  ABBA AB::CD A::B::C::D::E::F A::B::CD::EF A::B::CDEF A::BC::D::EF A::BCD::E::F AB::CD::EF ABC::DEF
sort {cmp} packages: A::B::C::D::E::F A::B::CD::EF A::B::CDEF A::BC::D::EF A::BCD::E::F AB::CD AB::CD::EF ABBA ABC::DEF
sort {<=>} packages: ABBA AB::CD ABC::DEF A::B::CDEF AB::CD::EF A::B::CD::EF A::BC::D::EF A::BCD::E::F A::B::C::D::E::F


=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen << <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut


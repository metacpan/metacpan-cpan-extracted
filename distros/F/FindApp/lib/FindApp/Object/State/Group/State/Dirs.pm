package FindApp::Object::State::Group::State::Dirs;

use v5.10;
use strict;
use warnings;
use mro "c3";

use FindApp::Utils qw(
    :assert
    :debug
    :foreign 
    :list
);

sub all_defined {
    unless (@_ == grep {defined} @_) {
        subcroak_N(2, "undefined arguments forbidden");
    }
}

use namespace::clean;

################################################################

use FindApp::Utils ":overload";

use overload reverse (
    as_string     => qw( "" ),
    as_number     => qw( 0+ ),
    op_equals     => qw( == ),
    op_notequals  => qw( != ),
    op_eq         => qw( eq ),
    op_ne         => qw( ne ),
);

sub op_eq {
    my($this, $that, $swapped) = @_;
    no overloading;
    local $" = "\0"; # these are path elements, so NUL illegal
    return "@$this" eq "@$that";  # "guaranteed" to be ordered
}

sub op_ne { !&op_eq }

sub class {
    my $self = shift;
    good_args(@_ == 0);
    return blessed($self) || $self;
}

sub object {
    my $self = shift;
    good_args(@_ == 0);
    croak "not an object -- and no old class object to uncache" unless blessed $self;
    return $self;
}

sub new { &ENTER_TRACE_3;
    my($invocant, @values) = @_;
    all_defined(@values);
    my $class = blessed($invocant) || $invocant;
    my $old   = blessed($invocant) && $invocant;
    my $new   = bless([], $class);
    $new->copy($old)    if $old;
    $new->add(@values)  if @values;
    return $new;
}

sub copy { &ENTER_TRACE_3;
    good_args(@_ == 2);
    my($new, $old) = @_;
    $new->set($old->get) if $old->count;
}

sub get {
    my $self = shift;
    good_args(@_ == 0);
    return wantarray ? @$self
                     : $$self[0];
}

sub set { &ENTER_TRACE_3;
    my($self, @values) = @_;
    all_defined(@values);
    @values = map { (ref && reftype eq "ARRAY") ? @$_ : $_ } @values;
    @$self = uniq sort @values;
    return $self;
}

sub reset { &ENTER_TRACE_3;
    my $self = shift;
    good_args(@_ == 0);
    my @old_bits = @$self;
    @$self = ();
    return @old_bits;
}

# these should not exist
sub first {
    my $self = shift;
    good_args(@_ == 0);
    return $$self[0];
}

# these should not exist
sub last {
    my $self = shift;
    good_args(@_ == 0);
    return $$self[-1];
}

sub count {
    my $self = shift;
    good_args(@_ == 0);
    return 0+@$self;
}

sub has { &ENTER_TRACE_3;
    my($self, @values) = @_;
    good_args(@values != 0);
    all_defined(@values);
    my %have = map { $_ => 1 } $self->get;
    for my $value (@values) {
        $have{$value} || return 0;
    }
    return 1;
}

use Carp qw(cluck);

sub add { &ENTER_TRACE_3;
    my($self, @values) = @_;
    good_args(@values != 0);
    all_defined(@values);
    return $self->set($self->get, @values);
}

sub del { &ENTER_TRACE_3;
    my($self, @values) = @_;
    good_args(@values != 0);
    all_defined(@values);
    cluck "silly bits" if $values[0] eq "1";
    my %have = map { ($_ => 1) } $self->get;
    my %gone = map { ($_ => 1) } @values;
    my @removed = grep { $have{$_} && $gone{$_} } @values;
    $self->set(grep { ! $gone{$_} } keys %have);
    return @removed;
}

1;

=encoding utf8

=head1 NAME

FindApp::Object::State::Group::State::Dirs - Implement the FindApp group-directory set object

=head1 DESCRIPTION

This is the class that each L<FindApp::Object::State::Group> object has three of, 
one for each of I<allowed>, I<wanted>, I<found>.  Each Dirs object represents
a set of paths.

=head2 Methods

=over

=item new LIST

Creates, initializes, and returns a Dirs object.  The list is a list
of filenames.  As a class method:
 
    use  FindApp::Object::State::Group::Dirs;
    my $ob1 = FindApp::Object::State::Group::Dirs->new("lib", "t/lib");

Invoked as an instance method, the old object's contents are added
to the set, making it the union of the old object set and the parameter list.

    my $ob2 = $ob1->new("testlib");

Now C<< $ob2->get >> returns a list of three items: F<lib>, F<t/lib>, and F<testlib>.

If you don't want the old object's contents, don't call it as an object method:
use its class instead:

    my $ob3 = $ob2->class->new("bin");

Now $ob3 will hold only the single new item.

=item copy OLD

Method used to copy an old object into a new one.  This sets the
new object to be the same set as the old one's only if the old one
has anything in its set.  So this:

    $new->copy($old);

is like this:

    $new->add($old->get) if $old->count;

This is called implicitly by the C<new> method as just explained.

=item class

Returns the package of the blessed argument. This is useful for 
inherited constructors so that you don't need to know the exact
class. See L</new>.

=item object

Returns the object itself.  This is the identity function.

=item as_number

Overload for comparing whether two objects are truly the same reference.
Used by the C<==> and C<!=> operators.

=item as_string

Overload for pretty-printing an object's contents.
This is I<not> what is used by the C<eq> and C<ne> operators.

=item add LIST

Add a list of directories to the object.  Duplicates are suppressed.

=item has LIST

Returns true if the object has all the I<LIST> elements, and false otherwise.

=item del LIST

Remove all I<LIST> elements from the object, and return those deleted.

=item count

Report how many elements are in the Dirs set.

=item first

Return one element, or I<undef> if there isn't one.
This should not exist, because these are to be thought of as sets not lists.

=item get

Return a list of the set contents in list context, and just one of them otherwise.

=item last

Return one element, or I<undef> if there isn't one.
This should not exist, because these are to be thought of as sets not lists.

=item reset

Clear the set, and return the deleted list.

=item set LIST

Destructively make the current object equal to the LIST and return the object.
One level of array reference will be interpolated.

=item op_eq

Used to implement the C<eq> operator, this compares contents.

=item op_equals

Used to implement the C<==> operator, this compares addresses.

=item op_ne

The opposite of C<op_eq>.

=item op_notequals

The opposite of C<op_equals>.

=back

=head1 ENVIRONMENT

=over

=item FINDAPP_TRACE

If the FINDAPP_TRACE variable is set to 3 or higher, will trace
some method calls.  

    tchrist% perl -MFindApp::Object::State::Group::Dirs -E 'say FindApp::Object::State::Group::Dirs->new(<R B G>)->add(<C M Y>)->get'
    BCGMRY

    tchrist% env FINDAPP_TRACE=3 perl -MFindApp::Object::State::Group::Dirs -E 'say FindApp::Object::State::Group::Dirs->new(<R B G>)->add(<C M Y>)->get'
    FindApp::Object::State::Group::Dirs::new FindApp::Object::State::Group::Dirs R B G
    FindApp::Object::State::Group::Dirs::add FindApp::Object::State::Group::Dirs=ARRAY(0x7f9e8b02f780) R B G
    FindApp::Object::State::Group::Dirs::set FindApp::Object::State::Group::Dirs=ARRAY(0x7f9e8b02f780) R B G
    FindApp::Object::State::Group::Dirs::add FindApp::Object::State::Group::Dirs=ARRAY(0x7f9e8b02f780) C M Y
    FindApp::Object::State::Group::Dirs::set FindApp::Object::State::Group::Dirs=ARRAY(0x7f9e8b02f780) B G R C M Y
    BCGMRY

=item FINDAPP_DEBUG_SHORTEN

If true, this will shorten the trace and debug output by abbreviating
package names that start with "FindApp".

    tchrist% FINDAPP_DEBUG_SHORTEN=1 FINDAPP_TRACE=3 perl -MFindApp::Object::State::Group::Dirs -E 'say FindApp::Object::State::Group::Dirs->new(<R B G>)->add(<C M Y>)->get'
    f:o:s:g:Dirs::new f:o:s:Group::Dirs R B G
    f:o:s:g:Dirs::add f:o:s:Group::Dirs=ARRAY(0x7fc00b030738) R B G
    f:o:s:g:Dirs::set f:o:s:Group::Dirs=ARRAY(0x7fc00b030738) R B G
    f:o:s:g:Dirs::add f:o:s:Group::Dirs=ARRAY(0x7fc00b030738) C M Y
    f:o:s:g:Dirs::set f:o:s:Group::Dirs=ARRAY(0x7fc00b030738) B G R C M Y
    BCGMRY

Which is much easier to read.  The last two components in the
fully-qualfied name are always left as is, with everything else clipped to
a single lowercase letter and a single colon instead of a double one for
the seprator.

Likewise, instead of this:

    tchrist% perl -MFindApp::Object::State::Group::Dirs -e 'print FindApp::Object::State::Group::Dirs->new(<R B G>)->add(<C M Y>)'
    bless(["B", "C", "G", "M", "R", "Y"], "FindApp::Object::State::Group::Dirs"); # FindApp::Object::State::Group::Dirs=ARRAY(0x7fcaf302f018)


With the shortening, you get this:

    tchrist% FINDAPP_DEBUG_SHORTEN=1 perl -MFindApp::Object::State::Group::Dirs -e 'print FindApp::Object::State::Group::Dirs->new(<R B G>)->add(<C M Y>)'
    bless(["B", "C", "G", "M", "R", "Y"], "f:o:s:Group::Dirs"); # FindApp::Object::State::Group::Dirs=ARRAY(0x7fc79102f030)

The object type in the comment is not subject to shortening.

=back

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

Do not rely on the internal representation of these
object being an array reference.

=head1 AUTHOR

Tom Christiansen C<< <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut


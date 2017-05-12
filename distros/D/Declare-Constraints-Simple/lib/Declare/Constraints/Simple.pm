=head1 NAME

Declare::Constraints::Simple - Declarative Validation of Data Structures

=cut

package Declare::Constraints::Simple;
use warnings;
use strict;

use base 'Declare::Constraints::Simple::Library::Exportable';

our $VERSION = 0.03;

=head1 SYNOPSIS

  use Declare::Constraints::Simple-All;

  my $profile = IsHashRef(
                    -keys   => HasLength,
                    -values => IsArrayRef( IsObject ));

  my $result1 = $profile->(undef);
  print $result1->message, "\n";    # 'Not a HashRef'

  my $result2 = $profile->({foo => [23]});

  print $result2->message, "\n";    # 'Not an Object'

  print $result2->path, "\n";       
                    # 'IsHashRef[val foo].IsArrayRef[0].IsObject'

=head1 DESCRIPTION

The main purpose of this module is to provide an easy way to build a
profile to validate a data structure. It does this by giving you a set of
declarative keywords in the importing namespace.

=head1 USAGE

This is just a brief intro. For details read the documents mentioned in
L<SEE ALSO>.

=head2 Constraint Import

  use Declare::Constraints::Simple-All;

The above command imports all constraint generators in the library into
the current namespace. If you want only a selection, use C<only>:

  use Declare::Constraints::Simple
      Only => qw(IsInt Matches And);

You can find all constraints (and constraint-like generators, like
operators. In fact, C<And> above is an operator. They're both implemented
equally, so the distinction is a merely philosophical one) documented in
the L<Declare::Constraints::Simple::Library> pod. In that document you
will also find the exact parameters for their usage, so this here is just
a brief Intro and not a coverage of all possibilities.

=head2 Building a Profile

You can use these constraints by building a tree that describes what data
structure you expect. Every constraint can be used as sub-constraint, as
parent, if it accepts other constraints, or stand-alone. If you'd just 
say

  my $check = IsInt;
  print "yes!\n" if $check->(23);

it will work too. This also allows predefining tree segments, and nesting
them:

  my $id_to_objects = IsArrayRef(IsObject);

Here C<$id_to_objects> would give it's OK on an array reference 
containing a list of objects. But what if we now decide that we actually 
want a hashref containing two lists of objects? Behold:

  my $object_lists = 
    IsHashRef( HasAllKeys( qw(good bad) ),
               OnHashKeys( good => $id_to_objects,
                           bad  => $id_to_objects ));

As you can see, constraints like C<IsArrayRef> and C<IsHashRef> allow you
to apply constraints to their keys and values. With this, you can step
down in the data structure.

=head2 Applying a Profile to a Data Structure

Constraints return just code references that can be applied to one value
(and only one value) like this:

  my $result = $object_lists->($value);

After this call C<$result> contains a
L<Declare::Constraints::Simple::Result> object. The first think one wants
to know is if the validation succeeded:

  if ($result->is_valid) { ... }

This is pretty straight forward. To shorten things the result object also
L<overload>s it's C<bool>ean context. This means you can alternatively
just say

  if ($result) { ... }

However, if the result indicates a invalid data structure, we have a few
options to find out what went wrong. There's a human parsable message in
the C<message> accessor. You can override these by forcing it to a 
message in a subtree with the C<Message> declaration. The C<stack> 
contains the name of the chain of constraints up to the point of failure.

You can use the C<path> accessor for a joined string path representing 
the stack.

=head2 Creating your own Libraries

You can declare a package as a library with

  use Declare::Constraints::Simple-Library;

which will install the base class and helper methods to define
constraints. For a complete list read the documentation in
L<Declare::Constraints::Simple::Library::Base>. You can use other
libraries as base classes to include their constraints in your export
possibilities. This means that with a package setup like

  package MyLibrary;
  use warnings;
  use strict;

  use Declare::Constraints::Simple-Library;
  use base 'Declare::Constraints::Simple::Library';

  constraint 'MyConstraint',
    sub { return _result(($_[0] >= 12), 'Value too small') };

  1;

you can do

  use MyLibrary-All;

and have all constraints, from the default library and yours from above,
installed into your requesting namespace. You can override a constraint
just by redeclaring it in a subclass.

=head2 Scoping

Sometimes you want to validate parts of a data structure depending on
another part of it. As of version 2.0 you can declare scopes and store
results in them. Here is a complete example:

  my $constraint =
    Scope('foo',
      And(
        HasAllKeys( qw(cmd data) ),
        OnHashKeys( 
          cmd => Or( SetResult('foo', 'cmd_a',
                       IsEq('FOO_A')),
                     SetResult('foo', 'cmd_b',
                       IsEq('FOO_B')) ),
          data => Or( And( IsValid('foo', 'cmd_a'),
                           IsArrayRef( IsInt )),
                      And( IsValid('foo', 'cmd_b'),
                           IsRegex )) )));

This profile would accept a hash references with the keys C<cmd> and
C<data>. If C<cmd> is set to C<FOO_A>, then C<data> has to be an array 
ref of integers. But if C<cmd> is set to C<FOO_B>, a regular expression 
is expected.

=head1 SEE ALSO

L<Declare::Constraints::Simple::Library>, 
L<Declare::Constraints::Simple::Result>,
L<Declare::Constraints::Simple::Base>,
L<Module::Install>

=head1 REQUIRES

L<Carp::Clan>, L<aliased>, L<Class::Inspector>, L<Scalar::Util>,
L<overload> and L<Test::More> (for build).

=head1 TODO

=over

=item *

Examples.

=item *

A list of questions that might come up, together with their answers.

=item *

A C<Custom> constraint that takes a code reference.

=item *

Create stack objects that stringify to the current form, but can hold
more data.

=item *

Give the C<Message> constraint the ability to get the generated 
constraint inserted in the message. A possibility would be to replace 
__Value__ and __Message__. It might also accept code references, which 
return strings.

=item *

Allow the C<IsCodeRef> constraint to accept further constraints. One 
might like to check, for example, the refaddr of a closure.

=item *

A C<Captures> constraint that takes a regex and can apply other
constraints to the matches.

=item *

???

=item *

Profit.

=back

=head1 INSTALLATION

  perl Makefile.PL
  make
  make test
  make install

For details read L<Module::Install>.

=head1 AUTHOR

Robert 'phaylon' Sedlacek C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This module is free software, you can redistribute it and/or modify it 
under the same terms as perl itself.

=cut

1;

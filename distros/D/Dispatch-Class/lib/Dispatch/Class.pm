package Dispatch::Class;

use warnings;
use strict;

our $VERSION = '0.02';

use Scalar::Util qw(blessed);

use parent 'Exporter::Tiny';
our @EXPORT_OK = qw(
    class_case
    dispatch
);

sub class_case {
    my @prototable = @_;
    sub {
        my ($x) = @_;
        my $blessed = blessed $x;
        my $ref = ref $x;
        my $DOES;
        my @table = @prototable;
        while (my ($key, $value) = splice @table, 0, 2) {
            return $value if
                !defined $key ? !defined $x :
                $key eq '*' ? 1 :
                $key eq ':str' ? !$ref :
                $key eq $ref ? 1 :
                $blessed && ($DOES ||= $x->can('DOES') || 'isa', $x->$DOES($key))
            ;
        }
        ()
    }
}

sub dispatch {
    my $chk = &class_case;
    sub { ($chk->($_[0]) || return)->($_[0]) }
}

'ok'

__END__

=head1 NAME

Dispatch::Class - dispatch on the type (class) of an argument

=head1 SYNOPSIS

  use Dispatch::Class qw(
    class_case
    dispatch
  );
  
  # analyze the class of an object
  my $analyze = class_case(
    'Some::Class'  => 1,
    'Other::Class' => 2,
    'UNIVERSAL'    => "???",
  );
  my $foo = $analyze->(Other::Class->new);  # 2
  my $bar = $analyze->(IO::Handle->new);    # "???"
  my $baz = $analyze->(["not an object"]);  # undef

  # build a dispatcher
  my $dispatch = dispatch(
    'Dog::Tiny' => sub { ... },  # handle objects of the class Dog::Tiny
    'Dog'       => sub { ... },
    'Mammal'    => sub { ... },
    'Tree'      => sub { ... },
  
    'ARRAY'     => sub { ... },  # handle array refs
  
    ':str'      => sub { ... },  # handle non-reference strings
  
    '*'         => sub { ... },  # handle any value
  );
  
  # call the appropriate handler, passing $obj as an argument
  my $result = $dispatch->($obj);

=head1 DESCRIPTION

This module offers a (mostly) simple way to check the class of an object and
handle specific cases specially.

=head2 Functions

The following functions are available and can be imported on request:

=over

=item C<class_case>

C<class_case> takes a list of C<KEY, VALUE> pairs and returns a code reference
that (when called on an object) will analyze the object's class according to
the rules described below and return the corresponding I<VALUE> of the first
matching I<KEY>.

Example:

  my $subref = class_case(
    KEY1 => VALUE1,
    KEY2 => VALUE2,
    ...
  );
  my $value = $subref->($some_object);

This will check the class of C<$some_object> against C<KEY1>, C<KEY2>, ... in
order and return the corresponding C<VALUEn> of the first match. If no key
matches, an empty list/undef is returned in list/scalar context, respectively.

The following things can be used as keys:

=over

=item C<*>

This will match any value. No actual check is performed.

=item C<:str>

This special key will match any non-reference.

=item C<SCALAR>, C<ARRAY>, C<HASH>, ...

These values match references of the specified type even if they aren't objects
(i.e. not L<C<bless>ed|perlfunc/bless>). That is, for unblessed references the
string returned by L<C<ref>|perlfunc/ref> is compared with
L<C<eq>|perlop/"Equality Operators">.

=item CLASS

Any other string is interpreted as a class name and matches if the input value
is an object for which C<< $obj->isa($CLASS) >> is true. To match any kind of
object (blessed value), use the key C<'UNIVERSAL'>.

Starting with L<Perl 5.10.0|perl5100delta/UNIVERSAL::DOES()> Perl supports
checking for roles with L<C<DOES>|UNIVERSAL/obj-DOES-ROLE->, so
C<Dispatch::Class> actually uses C<< $obj->DOES($CLASS) >> instead of C<isa>.
This still returns true for normal base classes but it also accepts roles that
have been composed into the object's class.

=back

=item C<dispatch>

This works like C<class_case> above, but the I<VALUE>s must be code references
and get invoked automatically:

  sub dispatch {
    my $analyze = class_case @_;
    sub {
      my ($obj) = @_;
      my $handler = $analyze->($obj) or return;
      $handler->($obj)
    }
  }

That is, the matching object is passed on to the matched I<VALUE>s and the
return value of the inner sub is whatever the handler returns (or the empty
list/undef if no I<KEY> matches).

=back

This module uses L<C<Exporter::Tiny>|Exporter::Tiny>, so you can rename the
imported functions at L<C<use>|perlfunc/use> time.

=head1 SEE ALSO

L<Exporter::Tiny>

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013, 2014 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

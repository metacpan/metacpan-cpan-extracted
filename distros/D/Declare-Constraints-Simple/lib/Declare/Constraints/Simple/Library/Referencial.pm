=head1 NAME

Declare::Constraints::Simple::Library::Referencial - Ref Constraints

=cut

package Declare::Constraints::Simple::Library::Referencial;
use warnings;
use strict;

use Declare::Constraints::Simple-Library;

=head1 SYNOPSIS

  # scalar or array references
  my $scalar_or_array = IsRefType( qw(SCALAR ARRAY) );

  # scalar reference
  my $int_ref = IsScalarRef( IsInt );

  # accept mappings of ids to objects with "name" methods
  my $id_obj_map = 
    IsHashRef( -keys   => IsInt,
               -values => And( IsObject,
                               HasMethods('name') ));

  # an integer list
  my $int_list = IsArrayRef( IsInt );

  # accept code references
  my $is_closure = IsCodeRef;

  # accept a regular expression
  my $is_regex = IsRegex;

=head1 DESCRIPTION

This library contains those constraints that can test the validity of
references and their types.

=head1 CONSTRAINTS

=head2 IsRefType(@types)

Valid if the value is a reference of a kind in C<@types>.

=cut

constraint 'IsRefType',
    sub {
        my (@types) = @_;
        return sub { 
            return _false('Undefined Value') unless defined $_[0];
            my @match = grep { ref($_[0]) eq $_ } @types;
            return scalar(@match) 
                ? _true 
                : _false('No matching RefType');
        };
    };

=head2 IsScalarRef($constraint)

This is true if the value is a scalar reference. A possible constraint
for the scalar references target value can be passed. E.g.

  my $test_integer_ref = IsScalarRef(IsInt);

=cut

constraint 'IsScalarRef',
    sub {
        my @vc = @_;
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _false('Not a ScalarRef') 
                unless ref($_[0]) eq 'SCALAR';
            return _true unless @vc;
            my $result = _apply_checks(${$_[0]}, \@vc);
            return $result unless $result->is_valid;
            return _true;
        };
    };

=head2 IsArrayRef($constraint)

The value is valid if the value is an array reference. The contents of
the array can be validated by passing an other C<$constraint> as 
argument.

The stack or path part of C<IsArrayRef> is C<IsArrayRef[$index]> where
C<$index> is the index of the failing element.

=cut

constraint 'IsArrayRef',
    sub {
        my @vc = @_;
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _false('Not an ArrayRef') 
                unless ref($_[0]) eq 'ARRAY';
            for (0 .. $#{$_[0]}) { 
                my $result = _apply_checks($_[0][$_], \@vc, $_);
                return $result unless $result->is_valid;
            }
            return _true;
        };
    };

=head2 IsHashRef(-keys => $constraint, -values => $constraint)

True if the value is a hash reference. It can also take two named
parameters: C<-keys> can pass a constraint to check the hashes keys,
C<-values> does the same for its values.

The stack or path part of C<IsHashRef> looks like 
C<IsHashRef[$type $key]> where C<$type> is either C<val> or C<key> 
depending on what was validated, and C<$key> being the key that didn't 
pass validation.

=cut

constraint 'IsHashRef',
    sub {
        my %def = @_;
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _false('Not a HashRef') unless ref($_[0]) eq 'HASH';
            if (my $c = $def{'-values'}) {
                for (keys %{$_[0]}) {
                    my $r = 
                        _apply_checks($_[0]{$_}, _listify($c), "val $_");
                    return $r unless $r->is_valid;
                }
            }
            if (my $c = $def{'-keys'}) {
                for (keys %{$_[0]}) {
                    my $r = _apply_checks($_, _listify($c), "key $_");
                    return $r unless $r->is_valid;
                }
            }
            return _true;
        };
    };

=head2 IsCodeRef()

Code references have to be valid to pass this constraint.

=cut

constraint 'IsCodeRef',
    sub {
        return sub { 
            return _false('Undefined Value') unless defined $_[0];
            return _result((ref($_[0]) eq 'CODE'), 'Not a CodeRef');
        };
    };

=head2 IsRegex()

True if the value is a regular expression built with C<qr>. B<Note>
however, that a simple string that could be used like C</$rx/> will
not pass this constraint. You can combine multiple constraints with
L<And(@constraints)> though.

=cut

constraint 'IsRegex',
    sub {
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _result((ref($_[0]) eq 'Regexp'),
                'Not a Regular Expression');
        };
    };

=head1 SEE ALSO

L<Declare::Constraints::Simple>, L<Declare::Constraints::Simple::Library>

=head1 AUTHOR

Robert 'phaylon' Sedlacek C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This module is free software, you can redistribute it and/or modify it 
under the same terms as perl itself.

=cut

1;

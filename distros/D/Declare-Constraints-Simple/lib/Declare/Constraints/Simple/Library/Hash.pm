=head1 NAME

Declare::Constraints::Simple::Library::Hash - Hash Constraints

=cut

package Declare::Constraints::Simple::Library::Hash;
use warnings;
use strict;

use Declare::Constraints::Simple-Library;

=head1 SYNOPSIS

  my $constraint = And(

    # make sure all keys are present
    HasAllKeys( qw(foo bar) ),

    # constraints for the keys
    OnHashKeys( foo => IsInt, bar => HasLength )

  );

=head1 DESCRIPTION

This module contains all constraints that can be applied to hash
references.

=head2 HasAllKeys(@keys)

The value has to be a hashref, and contain all keys listed in 
C<@keys> to pass this constraint.

The stack or path part of C<HasAllKeys> is C<HasAllKeys[$key]> where
C<$key> is the missing key.

=cut

constraint 'HasAllKeys',
    sub {
        my @vk = @_;
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _false('Not a HashRef') unless ref($_[0]) eq 'HASH';
            for (@vk) {
                unless (exists $_[0]{$_}) {
                    _info($_);
                    return _false("No '$_' key present");
                }
            }
            return _true;
        };
    };

=head2 OnHashKeys(key => $constraint, key => $constraint, ...)

This allows you to pass a constraint for each specific key in
a hash reference. If a specified key is not in the validated
hash reference, the validation for this key is not done. To make
a key a requirement, use L<HasAllKeys(@keys)> above in combination
with this, e.g. like:

  And( HasAllKeys( qw(foo bar baz) )
       OnHashKeys( foo => IsInt,
                   bar => Matches(qr/bar/),
                   baz => IsArrayRef( HasLength )));

Also, as you might see, you don't have to check for C<IsHashRef>
validity here. The hash constraints are already doing that by
themselves.

The stack or path part of C<OnHashKeys> looks like C<OnHashKeys[$key]>
where C<$key> is the key of the failing value.

=cut

constraint 'OnHashKeys',
    sub {
        my %def = my @def = @_;
        my @key_order;
        while (my $key = shift @def) {
            my $val = shift @def;
            push @key_order, $key;
        }
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _false('Not a HashRef') unless ref($_[0]) eq 'HASH';
            for (@key_order) {
                my @vc = @{_listify($def{$_})};
                next unless exists $_[0]{$_};
                my $r = _apply_checks($_[0]{$_}, \@vc, $_);
                return $r unless $r->is_valid;
            }
            return _true;
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

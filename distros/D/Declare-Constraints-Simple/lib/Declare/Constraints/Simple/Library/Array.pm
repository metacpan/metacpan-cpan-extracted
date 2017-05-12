=head1 NAME

Declare::Constraints::Simple::Library::Array - Array Constraints

=cut

package Declare::Constraints::Simple::Library::Array;
use warnings;
use strict;

use Declare::Constraints::Simple-Library;
use Carp::Clan qw(^Declare::Constraints::Simple);

=head1 SYNOPSIS

  # accept a list of pairs
  my $pairs_validation = IsArrayRef( HasArraySize(2,2) );

  # integer => object pairs
  my $pairs = And( OnEvenElements(IsInt), 
                   OnOddElements(IsObject) );

  # a three element array
  my $tri = And( HasArraySize(3,3),
                 OnArrayElements(0, IsInt,
                                 1, IsDefined,
                                 2, IsClass) );

=head1 DESCRIPTION

This module contains all constraints that can be applied to array
references.

=head1 CONSTRAINTS

=head2 HasArraySize([$min, [$max]])

With C<$min> defaulting to 1. So a specification of

  my $profile = HasArraySize;

checks for at least one value. To force an exact size of the array,
specify the same values for both:

  my $profile = HasArraySize(3, 3);

=cut

constraint 'HasArraySize',
    sub {
        my ($min, $max) = @_;
        $min = 1 unless defined $min;
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _false('Not an ArrayRef') 
                unless ref($_[0]) eq 'ARRAY';
            return _false("Less than $min Array elements")
                unless scalar(@{$_[0]}) >= $min;
            return _true 
                unless $max;
            return _false("More than $max Array elements")
                unless scalar(@{$_[0]}) <= $max;
            return _true;
        };
    };

=head2 OnArrayElements($key => $constraint, $key => $constraint, ...)

Applies the the C<$constraint>s to the corresponding C<$key>s if they are
present. For required keys see C<HasArraySize>.

=cut

constraint 'OnArrayElements',
    sub {
        my %keymap = @_;
        my @keys   = sort keys %keymap;
        for (@keys) {
            croak "Not an array index: $_" if $_ =~ /\D/;
        }
        
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _false('Not an ArrayRef') 
                unless ref($_[0]) eq 'ARRAY';
            for my $k (@keys) {
                last if $k > $#{$_[0]};
                my $r = $keymap{$k}->($_[0][$k]);
                _info($k);
                return $r unless $r->is_valid;
            }
            return _true;
        }
    };

=head2 OnEvenElements($constraint)

Runs the constraint on all even elements of an array. See also 
C<OnOddElements>.

=cut

constraint 'OnEvenElements',
    sub {
        my ($c) = @_;

        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _false('Not an ArrayRef')
                unless ref($_[0]) eq 'ARRAY';
            my $p = 0;
            while ($p <= $#{$_[0]}) {
                my $r = $c->($_[0][$p]);
                _info($p);
                return $r unless $r->is_valid;
                $p += 2;
            }
            return _true;
        };
    };


=head2 OnOddElements($constraint)

Runs the constraint on all odd elements of an array. See also
C<OnEvenElements>.

=cut

constraint 'OnOddElements',
    sub {
        my ($c) = @_;

        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _false('Not an ArrayRef')
                unless ref($_[0]) eq 'ARRAY';
            my $p = 1;
            while ($p <= $#{$_[0]}) {
                my $r = $c->($_[0][$p]);
                _info($p);
                return $r unless $r->is_valid;
                $p += 2;
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

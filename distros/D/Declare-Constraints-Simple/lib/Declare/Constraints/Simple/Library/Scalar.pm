=head1 NAME

Declare::Constraints::Simple::Library::Scalar - Scalar Constraints

=cut

package Declare::Constraints::Simple::Library::Scalar;
use warnings;
use strict;

use Declare::Constraints::Simple-Library;

use Carp::Clan qw(^Declare::Constraints::Simple);

=head1 SYNOPSIS

  # match one of a set of regexes
  my $some_regexes = Matches(qr/foo/, qr/bar/);

  # allow only defined values
  my $is_defined = IsDefined;

  # between 5 and 50 chars
  my $five_to_fifty = HasLength(5, 50);

  # match against a set of values
  my $command_constraint = IsOneOf(qw(create update delete));

  # check for trueness
  my $is_true = IsTrue;

  # simple equality
  my $is_foo = IsEq('foo');

=head1 DESCRIPTION

This library contains all constraints to validate scalar values.

=head1 CONSTRAINTS

=head2 Matches(@regex)

  my $c = Matches(qr/foo/, qr/bar/);

If one of the parameters matches the expression, this is true.

=cut

constraint 'Matches',
    sub {
        my @rx = @_;
        croak 'Matches needs at least one Regexp as argument'
            unless @rx;
        for (@rx) {
            croak 'Matches only takes Regexps as arguments'
                unless ref($_) eq 'Regexp';
        }
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            for (@rx) {
                return _true if $_[0] =~ /$_/;
            }
            return _false('Regex does not match');
        };
    };

=head2 IsDefined()

True if the value is defined.

=cut

constraint 'IsDefined',
    sub {
        return sub { 
            return _result((defined($_[0]) ? 1 : 0), 'Undefined Value');
        };
    };

=head2 HasLength([$min, [$max]])

Is true if the value has a length above C<$min> (which defaults to 1> and,
if supplied, under the value of C<$max>. A simple

  my $c = HasLength;

checks if the value has a length of at least 1.

=cut

constraint 'HasLength',
    sub {
        my ($min, $max) = @_;
        $min = 1 unless defined $min;
        $max = 0 unless defined $max;
        return sub {
            my ($val) = @_;
            return _false('Undefined Value') unless defined $val;
            return _false('Value too short') unless $min <= length($val);
            return _true unless $max;
            return _result(((length($val) <= $max) ? 1 : 0), 
                'Value too long');
        };
    };

=head2 IsOneOf(@values)

True if one of the C<@values> equals the passed value. C<undef> values
work with this too, so

  my $c = IsOneOf(1, 2, undef);

will return true on an undefined value.

=cut

constraint 'IsOneOf',
    sub {
        my @vals = @_;
        return sub {
            for (@vals) {
                unless (defined $_) {
                    return _true unless defined $_[0];
                    next;
                }
                next unless defined $_[0];
                return _true if $_[0] eq $_;
            }
            return _false('No Value matches');
        };
    };

=head2 IsTrue()

True if the value evulates to true in boolean context.

=cut

constraint 'IsTrue', 
    sub {
        return sub { $_[0] ? _true : _false('Value evaluates to False') };
    };

=head2 IsEq($comparator)

Valid if the value is C<eq> the C<$comparator>.

=cut

constraint 'IsEq',
    sub {
        my ($compare) = @_;
        return sub { 
            return _result(
                ($compare eq $_[0]), 
                "'$_[0]' does not equal '$compare'"
            );
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

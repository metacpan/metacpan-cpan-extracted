=head1 NAME

Declare::Constraints::Simple::Library::OO - OO Constraints

=cut

package Declare::Constraints::Simple::Library::OO;
use warnings;
use strict;

use Declare::Constraints::Simple-Library;

use Class::Inspector;
use Scalar::Util ();

=head1 SYNOPSIS

  # accept objects or classes
  my $object_or_class = Or( IsObject, IsClass );

  # valid on objects with all methods
  my $proper_object = And( IsObject, 
                           HasMethods( qw(foo bar) ));

  # validate against date objects
  my $is_date_object = IsA('DateTime');

=head1 DESCRIPTION

This library contains the constraints for validating parameters in an
object oriented manner.

=head1 CONSTRAINTS

=head2 HasMethods(@methods)

Returns true if the value is an object or class that C<can>
all the specified C<@methods>.

The stack or path part of C<HasMethods> looks like C<HasMethods[$method]>
where C<$method> is the first found missing method.

=cut

constraint 'HasMethods',
    sub {
        my (@methods) = @_;
        return sub { 
            return _false('Undefined Value') unless defined $_[0];
            return _false('Not a Class or Object') 
                unless Scalar::Util::blessed($_[0])
                    or Class::Inspector->loaded($_[0]);

            for (@methods) { 
                unless ($_[0]->can($_)) {
                    _info($_);
                    return _false("Method $_ not implemented");
                }
            }

            return _true;
        };
    };

=head2 IsA(@classes)

Is true if the passed object or class is a subclass of one
of the classes mentioned in C<@classes>.

=cut

constraint 'IsA',
    sub {
        my (@classes) = @_;
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            for (@classes) { 
                return _true if eval { $_[0]->isa($_) };
            }
            return _false('No matching Class');
        };
    };

=head2 IsClass()

Valid if value is a loaded class.

=cut

constraint 'IsClass',
    sub {
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _result(Class::Inspector->loaded($_[0]), 
                'Not a loaded Class');
        };
    };

=head2 IsObject()

True if the value is blessed.

=cut

constraint 'IsObject',
    sub {
        return sub {
            return _false('Undefined Value') unless defined $_[0];
            return _result(Scalar::Util::blessed($_[0]), 
                'Not an Object');
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

=head1 NAME

Declare::Constraints::Simple::Library::General - General Constraints

=cut

package Declare::Constraints::Simple::Library::General;
use warnings;
use strict;

use Declare::Constraints::Simple-Library;

use Carp::Clan qw(^Declare::Constraints::Simple);

=head1 SYNOPSIS

  # custom error messages
  my $constraint = 
    And( Message( 'You need to specify a Value', IsDefined ),
         Message( 'The specified Value is not an Int', IsInt ));

  # build results
  my $valid   = ReturnTrue;
  my $invalid = ReturnFalse('Just because');

=head1 DESCRIPTION

This library is meant to contain those constraints and constraint-like
elements that apply generally to the whole framework.

=head1 CONSTRAINTS

=head2 Message($message, $constraint)

Overrides the C<message> set on the result object for failures in
C<$constraint>. For example:

  my $message = 'How hard is it to give me a number?';
  my $constraint = Message($message, IsNumber);

  my $result = $constraint->('duh...');
  print $result->message, "\n";

The C<Message> constraint overrides the error message returned by it's
whole subtree, however, the C<Message> specification nearest to the point
of failure will win. So while this

  my $constraint = Message( 'Foo',
                            IsArrayRef( Message( 'Bar', IsInt )));

  my $result = $constraint->(['I am not an Integer']);
  print $result->message;

will print C<Bar>, this

  my $result = $constraint->('I\'m not even an ArrayRef');
  print $result->message;

will output C<Foo>.

=cut

constraint 'Message',
    sub {
        my ($msg, $c) = @_;
        return sub {
            return _with_message($msg, $c, @_);
        };
    };

=head2 Scope($name, $constraint)

Executes the passed C<$constraint> in a newly generated scope named
C<$name>.

=cut

constraint 'Scope',
    sub {
        my ($scope_name, $constraint) = @_;
        return sub {
            return _with_scope($scope_name, $constraint, @_);
        };
    };

=head2 SetResult($scope, $name, $constraint)

Stores the result ov an evaluation of C<$constraint> in C<$scope> under
C<$name>.

=cut

constraint 'SetResult',
    sub {
        my ($scope, $name, $constraint) = @_;
        return sub {
            my $result = $constraint->(@_);
            _set_result($scope, $name, $result);
            return $result;
        };
    };

=head2 IsValid($scope, $name)

Returns a true result if the result C<$name>, which has to have been stored
previously in the scope named C<$scope>, was valid.

=cut

constraint 'IsValid',
    sub {
        my ($scope, $name) = @_;
        return sub {
            _info("$scope:$name");
            return _false unless _has_result($scope, $name);
            my $result = _get_result($scope, $name);
            return _result($result, 
                "Value '$name' in scope '$scope' is invalid");
        };
    };

=head2 ReturnTrue()

Returns a true result.

=cut

constraint 'ReturnTrue',
    sub { return sub { _true } };

=head2 ReturnFalse($msg)

Returns a false result containing C<$msg> as error message.

=cut

constraint 'ReturnFalse',
    sub { my $msg = shift; return sub { _false($msg) } };

=head1 SEE ALSO

L<Declare::Constraints::Simple>, L<Declare::Constraints::Simple::Library>

=head1 AUTHOR

Robert 'phaylon' Sedlacek C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This module is free software, you can redistribute it and/or modify it 
under the same terms as perl itself.

=cut

1;

=head1 NAME

Declare::Constraints::Simple::Library::Base - Library Base Class

=cut

package Declare::Constraints::Simple::Library::Base;
use warnings;
use strict;

use aliased 'Declare::Constraints::Simple::Result';

use Carp::Clan qw(^Declare::Constraints::Simple);

our $FAIL_MESSAGE_DEFAULT = 'Validation Error';
our $FAIL_MESSAGE = '';
our $FAIL_INFO;
our %SCOPES;

use base 'Declare::Constraints::Simple::Library::Exportable';

=head1 SYNOPSIS

  package My::Constraint::Library;
  use warnings;
  use strict;

  # this installs the base class and helper functions
  use Declare::Constraints::Simple-Library;

  # we can also automagically provide other libraries
  # to the importer
  use base 'Declare::Constraints::Simple::Library::Numericals';

  # with this we define a constraint to check a value
  # against a serial number regular expression
  constraint 'SomeSerial',
    sub {
      return sub {
        return _true if $_[0] =~ /\d{3}-\d{3}-\d{4}/;
        return _false('Not in SomeSerial format');
      };
    };
 
  1;

=head1 DESCRIPTION

This base class contains the common library functionalities. This 
includes helper functions and install mechanisms.

=head1 METHODS

=head2 install_into($target)

Installs the base classes and helper functions into the C<$target>
namespace. The C<%CONSTRAINT_GENERATORS> package variable of that class
will be used as storage for it's constraints.

=cut

sub install_into {
    my ($class, $target) = @_;

    {   no strict 'refs';
        unshift @{$target . '::ISA'}, $class;

        *{$target . '::' . $_} = $class->can($_)
            for qw/ 
                    constraint
                    _apply_checks
                    _listify
                    _result
                    _false
                    _true
                    _info
                    _with_message
                    _with_scope
                    _set_result
                    _get_result
                    _has_result
                /;
    }

    1;
}

=head2 fetch_constraint_declarations()

Class method. Returns all constraints registered to the class.

=cut

sub fetch_constraint_declarations {
    my ($class) = @_;
    
    {   no strict 'refs';
        no warnings;
        return keys %{$class . '::CONSTRAINT_GENERATORS'};
    }
}

=head2 fetch_constraint_generator($name)

Class method. Returns the constraint generator code reference registered
under C<$name>. The call will raise a C<croak> if the generator could not
be found.

=cut

sub fetch_constraint_generator {
    my ($class, $name) = @_;

    my $generator = do {
        no strict 'refs';
        ${$class . '::CONSTRAINT_GENERATORS'}{$name};
    };
    croak "Unknown Constraint Generators: $name"
        unless $generator;

    return $class->prepare_generator($name, $generator);
}

=head2 prepare_generator($constraint_name, $generator)

Class method. This wraps the C<$generator> in a closure that provides
stack and failure-collapsing decisions.

=cut

sub prepare_generator {
    my ($class, $constraint, $generator) = @_;
    return sub {
        my (@g_args) = @_;
        my $closure = $generator->(@g_args);

        return sub {
            my (@c_args) = @_;

            local $FAIL_INFO;
            my $result = $closure->(@c_args);
            my $info = '';
            if ($FAIL_INFO) {
                $info = $FAIL_INFO;
                $info =~ s/([\[\]])/\\$1/gsm;
                $info = "[$info]";
            }
            $result->add_to_stack($constraint . $info) unless $result;

            return $result;
        };
    };
}

=head2 add_constraint_generator($name, $code)

Class method. The actual registration method, used by C<constraint>.

=cut

sub add_constraint_generator {
    my ($class, $name, $code) = @_;

    {   no strict 'refs';
        ${$class . '::CONSTRAINT_GENERATORS'}{$name} = $code;
    }

    1;
}

=head1 HELPER FUNCTIONS

Note that some of the helper functions are prefixed with C<_>. Although
this means they are internal functions, it is ok to call them, as they
have a fixed API. They are not distribution internal, but library 
internal, and only intended to be used from inside constraints.

=head2 constraint($name, $code)

  constraint 'Foo', sub { ... };

This registers a new constraint in the calling library. Note that
constraints B<have to> return result objects. To do this, you can use the
helper functions L<_result($bool, $msg>, L<_true()> and L<_false($msg)>.

=cut

sub constraint {
    my ($name, $code) = @_;
    my $target = scalar(caller);
    $target->add_constraint_generator($name => $code);

    1;
}

=head2 _result($bool, $msg)

Returns a new result object. It's validity flag will depend on the
C<$bool> argument. The C<$msg> argument is the error message to use on
failure.

=cut

sub _result {
    my ($result, $msg) = @_;
    my $result_obj = Result->new;
    $result_obj->set_valid($result);
    $result_obj->set_message(
        $FAIL_MESSAGE || $msg || $FAIL_MESSAGE_DEFAULT)
        unless $result_obj->is_valid;
    return $result_obj;
}

=head2 _false($msg)

Returns a non-valid result object, with it's message set to C<$msg>.

=head2 _true()

Returns a valid result object.

=cut

sub _false { _result(0, @_) }
sub _true  { _result(1, @_) }

=head2 _info($info)

Sets the current failure info to use in the stack info part.

=cut

sub _info  { $FAIL_INFO = shift }

=head2 _apply_checks($value, \@constraints, [$info])

This applies all constraints in the C<\@constraints> array reference to
the passed C<$value>. You can optionally specify an C<$info> string to be
used in the stack of the newly created non-valid results.

=cut

sub _apply_checks {
    my ($value, $checks, $info) = @_;
    $checks ||= [];
    $FAIL_INFO = $info if $info;
    for (@$checks) {
        my $result = $_->($value);
        return $result unless $result->is_valid;
    }
    return _true;
}

=head2 _listify($value)

Puts C<$value> into an array reference and returns it, if it isn't 
already one.

=cut

sub _listify {
    my ($value) = @_;
    return (ref($value) eq 'ARRAY' ? $value : [$value]);
}

=head2 _with_message($msg, $closure, @args)

This is the internal version of the general C<Message> constraint. It 
sets the current overriden message to C<$msg> and executes the 
C<$closure> with C<@args> as arguments.

=cut

sub _with_message {
    my ($msg, $closure, @args) = @_;
    local $FAIL_MESSAGE = $msg;
    return $closure->(@args);
}

=head2 _with_scope($scope_name, $constraint, @args)

Applies the C<$constraint> to C<@args> in a newly created scope named
by C<$scope_name>.

=cut

sub _with_scope {
    my ($scope_name, $closure, @args) = @_;
    local %SCOPES = ($scope_name => {})
        unless exists $SCOPES{$scope_name};
    return $closure->(@args);
}

=head2 _set_result($scope, $name, $result)

Stores the given C<$result> unter the name C<$name> in C<$scope>.

=cut

sub _set_result {
    my ($scope, $name, $result) = @_;
    $SCOPES{$scope}{result}{$name} = $result;
    1;
}

=head2 _get_result($scope, $name)

Returns the result named C<$name> from C<$scope>.

=cut

sub _get_result {
    my ($scope, $name) = @_;
    return $SCOPES{$scope}{result}{$name};
}

=head2 _has_result($scope, $name)

Returns true only if such a result was registered already.

=cut

sub _has_result {
    my ($scope, $name) = @_;
    return exists $SCOPES{$scope}{result}{$name};
}

=head1 SEE ALSO

L<Declare::Constraints::Simple>, L<Declare::Constraints::Simple::Library>

=head1 AUTHOR

Robert 'phaylon' Sedlacek C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This module is free software, you can redistribute it and/or modify it 
under the same terms as perl itself.

=cut

1;

#!/usr/bin/perl -c

package Exception::Died;

=head1 NAME

Exception::Died - Convert simple die into real exception object

=head1 SYNOPSIS

  use Exception::Died;

  use warnings FATAL => 'all';
  eval { open $f, "x", "bad_open_mode" };
  Exception::Died->throw( message=>"cannot open" ) if $@;

  eval { die "Bum!\n" };
  if ($@) {
    my $e = Exception::Died->catch;
    $e->throw;
  };

  # Can replace die hook globally
  use Exception::Died '%SIG' => 'die';
  eval { die "Boom!\n" };
  print ref $@;           # "Exception::Died"
  print $@->eval_error;   # "Boom!"

  # Can be used in local scope only
  use Exception::Died;
  {
      local $SIG{__DIE__};
      Exception::Fatal->import('%SIG');
      eval { die "Boom!" };
      print ref $@;           # "Exception::Died"
      print $@->eval_error;   # "Boom!"
  };
  eval { die "Boom" };
  print ref $@;       # ""

  # Debugging with increased verbosity
  $ perl -MException::Died=:debug script.pl

  # Debugging one-liner script
  $ perl -MException::Died=:debug -ale '\
  use File::Temp; $tmp = File::Temp->new( DIR => "/notfound" )'

=head1 DESCRIPTION

This class extends standard L<Exception::Base> and converts eval's error into
real exception object.  The eval's error message is stored in I<eval_error>
attribute.

This class can be also used for debugging scripts with use simple
L<perlfunc/die> or L<Carp>.  You can raise verbosity level and print stack
trace if script doesn't use L<Exception::Base> and has stopped with
L<perlfunc/die>.

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.06';

use constant::boolean;


=head1 INHERITANCE

=over 2

=item *

extends L<Exception::Base>

=back

=cut

# Extend Exception::Base class
BEGIN {

=head1 CONSTANTS

=over

=item ATTRS : HashRef

Declaration of class attributes as reference to hash.

See L<Exception::Base> for details.

=back

=head1 ATTRIBUTES

This class provides new attributes.  See L<Exception::Base> for other
descriptions.

=over

=cut

    my %ATTRS = ();
    my @ATTRS_RO = ();

=item eval_error : Str {ro}

Contains the message from failed C<eval> block.  This attribute is
automatically filled on object creation.

  use Exception::Died '%SIG';
  eval { die "string" };
  print $@->eval_error;  # "string"

=cut

    push @ATTRS_RO, 'eval_error';

=item catch_can_rebless : Str {ro}

Contains the flag for C<catch> method which marks that this exception
object should be reblessed.  The flag is marked by internal C<__DIE__>
hook.

=cut

    push @ATTRS_RO, 'catch_can_rebless';

=item eval_attribute : Str = "eval_error"

Meta-attribute contains the name of the attribute which is filled if
error stack is empty.  This attribute will contain value of C<$@>
variable.  This class overrides the default value from
L<Exception::Base> class.

=cut

    $ATTRS{eval_attribute}    = 'eval_error';

=item string_attributes : ArrayRef[Str] = ["message", "eval_error"]

Meta-attribute contains the format of string representation of exception
object.  This class overrides the default value from L<Exception::Base>
class.

=cut

    $ATTRS{string_attributes} = [ 'message', 'eval_error' ];

=item default_attribute : Str = "eval_error"

Meta-attribute contains the name of the default attribute.  This class
overrides the default value from L<Exception::Base> class.

=back

=cut

    $ATTRS{default_attribute} = 'eval_error';

    use Exception::Base 0.21;
    Exception::Base->import(
        'Exception::Died' => {
            has   => { ro => \@ATTRS_RO },
            %ATTRS,
        },
        '+ignore_package' => [ 'Carp' ],
    );
};


## no critic RequireArgUnpacking
## no critic RequireCarping
## no critic RequireInitializationForLocalVars

=head1 IMPORTS

=over

=item use Exception::Died '%SIG';

=item use Exception::Died '%SIG' => 'die';

Changes C<$SIG{__DIE__}> hook to C<Exception::Died::__DIE__>.

=item use Exception::Died ':debug';

Changes C<$SIG{__DIE__}> hook and sets verbosity level to 4 (maximum).

=cut

# Handle %SIG tag
sub import {
    my ($pkg, @args) = @_;

    my @params;

    while (defined $args[0]) {
        my $name = shift @args;
        if ($name eq ':debug') {
            $name = '%SIG';
            @args = ('die', 'verbosity', 4, @args);
        };
        if ($name eq '%SIG') {
            if (defined $args[0] and $args[0] eq 'die') {
                shift @args;
            }
            # Handle die hook
            $SIG{__DIE__} = \&__DIE__;
        }
        else {
            # Other parameters goes to SUPER::import
            push @params, $name;
            push @params, shift @args if defined $args[0] and ref $args[0] eq 'HASH';
        };
    };

    if (@params) {
        return $pkg->SUPER::import(@params);
    };

    return TRUE;
};


=item no Exception::Died '%SIG';

Undefines C<$SIG{__DIE__}> hook.

=back

=cut

# Reset %SIG
sub unimport {
    my $pkg = shift;
    my $callpkg = caller;

    while (my $name = shift @_) {
        if ($name eq '%SIG') {
            # Undef die hook
            $SIG{__DIE__} = '';
        };
    };

    return TRUE;
};


=head1 CONSTRUCTORS

=over

=item catch(I<>) : Self|$@

This method overwrites the default C<catch> constructor.  It works as method
from base class and has one exception in its behavior.

  my $e = CLASS->catch;

If the popped value is an C<Exception::Died> object and has an attribute
C<catch_can_rebless> set, this object is reblessed to class I<$class> with its
attributes unchanged.  It is because original L<Exception::Base>-E<gt>C<catch>
method doesn't change exception class but it should be changed if
C<Exception::Died> handles C<$SIG{__DIE__}> hook.

  use Exception::Base
    'Exception::Fatal'  => { isa => 'Exception::Died' },
    'Exception::Simple' => { isa => 'Exception::Died' };
  use Exception::Died '%SIG' => 'die';

  eval { die "Died\n"; };
  my $e = Exception::Fatal->catch;
  print ref $e;   # "Exception::Fatal"

  eval { Exception::Simple->throw; };
  my $e = Exception::Fatal->catch;
  print ref $e;   # "Exception::Simple"

=back

=cut

# Rebless Exception::Died into another exception class
sub catch {
    my $self = shift;

    my $class = ref $self ? ref $self : $self;

    my $e = $self->SUPER::catch(@_);

    # Rebless if called as Exception::DiedDerivedClass->catch()
    if (do { local $@; local $SIG{__DIE__}; eval { $e->isa(__PACKAGE__) } }
        and ref $e ne $class and $e->{catch_can_rebless})
    {
        bless $e => $class;
    };

    return $e;
};


=head1 METHODS

=over

=item _collect_system_data(I<>) : Self

Collect system data and fill the attributes of exception object.  This method
is called automatically if exception if thrown.  This class overrides the
method from L<Exception::Base> class.

See L<Exception::Base>.

=back

=cut

# Collect system data
sub _collect_system_data {
    my $self = shift;

    if (not ref $@) {
        $self->{eval_error} = $@;
        while ($self->{eval_error} =~ s/\t\.\.\.propagated at (?!.*\bat\b.*).* line \d+( thread \d+)?\.\n$//s) { }
        $self->{eval_error} =~ s/( at (?!.*\bat\b.*).* line \d+( thread \d+)?\.?)?\n$//s;
        $self->{eval_error} = undef if $self->{eval_error} eq '';
    }
    elsif (do { my $e = $@; local $@; local $SIG{__DIE__}; eval { $e->isa('Exception::Died') } }) {
        $self->{eval_error} = $@->{eval_error};
        $self->{eval_error} = undef if defined $self->{eval_error} and $self->{eval_error} eq '';
    }
    else {
        $self->{eval_error} = undef;
    };

    return $self->SUPER::_collect_system_data(@_);
};


=head1 FUNCTIONS

=over

=item __DIE__()

This is a hook function for $SIG{__DIE__}.  This hook can be enabled with pragma:

  use Exception::Died '%SIG';

or manually, i.e. for local scope:

  {
      local $SIG{__DIE__};
      Exception::Died->import('%SIG');
      # ...
  };

=back

=cut

# Die hook
sub __DIE__ {
    if (not ref $_[0]) {
        # Do not recurse on Exception::Died & Exception::Warning
        die $_[0] if $_[0] =~ /^Exception::(Died|Warning): /;

        # Simple die: recover eval error
        my $message = $_[0];
        while ($message =~ s/\t\.\.\.propagated at (?!.*\bat\b.*).* line \d+( thread \d+)?\.\n$//s) { };
        $message =~ s/( at (?!.*\bat\b.*).* line \d+( thread \d+)?\.?)?\n$//s;

        my $e = __PACKAGE__->new;
        $e->{eval_error} = $message;
        $e->{catch_can_rebless} = TRUE;
        die $e;
    };
    # Otherwise: throw unchanged exception
    die $_[0];
};


1;


=begin umlwiki

= Class Diagram =

[                          <<exception>>
                          Exception::Died
 -----------------------------------------------------------------
 +catch_can_rebless : Bool {ro}
 +eval_error : Str {ro}
 #default_attribute : Str = "eval_error"
 #eval_attribute : Str = "eval_error"
 #string_attributes : ArrayRef[Str] = ["message", "eval_error"]
 -----------------------------------------------------------------
 <<create>> +catch() : Self|$@
 #_collect_system_data() : Self
 <<utility>> -__DIE__()
 <<constant>> +ATTRS() : HashRef                                  ]

[Exception::Died] ---|> [Exception::Base]

=end umlwiki

=head1 PERFORMANCE

The C<Exception::Died> module can change C<$SIG{__DIE__}> hook.  It
costs a speed for simple die operation.  The failure scenario was
benchmarked with default setting and with changed C<$SIG{__DIE__}> hook.

  -----------------------------------------------------------------------
  | Module                              | Without %SIG  | With %SIG     |
  -----------------------------------------------------------------------
  | eval/die string                     |      237975/s |        3069/s |
  -----------------------------------------------------------------------
  | eval/die object                     |      124853/s |       90575/s |
  -----------------------------------------------------------------------
  | Exception::Base eval/if             |        8356/s |        7984/s |
  -----------------------------------------------------------------------
  | Exception::Base try/catch           |        9218/s |        8891/s |
  -----------------------------------------------------------------------
  | Exception::Base eval/if verbosity=1 |       14899/s |       14300/s |
  -----------------------------------------------------------------------
  | Exception::Base try/catch verbos.=1 |       18232/s |       16992/s |
  -----------------------------------------------------------------------

It means that C<Exception::Died> with die hook makes simple die 30 times
slower.  However it has no significant difference if the exception
objects are used.

Note that C<Exception::Died> will slow other exception implementations,
like L<Class::Throwable> and L<Exception::Class>.

=head1 SEE ALSO

L<Exception::Base>.

=head1 BUGS

If you find the bug, please report it.

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

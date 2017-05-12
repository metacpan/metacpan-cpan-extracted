package Err;
use base qw(Exporter);

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);

# load Exception::Class and declare the Err::Exception baseclass
use Exception::Class ("Err::Exception");

our $VERSION = "0.02";
our @EXPORT_OK;

my %defaults;  # default arguments

########################################################################

sub _class_from_code {
    my $code = shift;
    return "Exception::Class::Base" unless length $code;
    return "Err::Exception" if $code eq ".";
    $code =~ s/\A\./Err::Exception::/x;
    $code =~ s/[.']/::/gx;
    return $code;
}

########################################################################

sub is_err($) {
    return unless blessed $_;
    return $_->isa(_class_from_code(shift));
}
push @EXPORT_OK, "is_err";

sub ex_is_err($) {
    return unless blessed $@;
    return $@->isa(_class_from_code(shift));
}
push @EXPORT_OK, "ex_is_err";

########################################################################

sub throw_err($$@) {  ## no critic (RequireFinalReturn)
    my $err_class = _class_from_code(shift);
    my $message = shift;

    # pre-populate our arguments from the defaults
    my %args = (%{ $defaults{ $err_class } || {} }, @_);

    # throw the exception
    $err_class->throw( message => $message, %args );
}
push @EXPORT_OK, "throw_err";

########################################################################

sub declare_err($%) {
    my $err_class = _class_from_code(shift);
    my %args = @_;

    # set the parent
    my $parent;
    $parent = _class_from_code(delete $args{isa}) if defined $args{isa};
    unless (defined $parent) {
        $parent = $err_class;

        # attempt to strip off the last ::whatever, but if we can't
        # (presumably because the class name only had one part) just
        # default to Err::Exception
        unless($parent =~ s/::[^:]+\z//x) {
            $parent = "Err::Exception";
        }
    }

    # set the description
    my $description = delete $args{description};

    # everything else is fields.  Remember them.
    $defaults{ $err_class } = \%args;

    # declare the exception with Exception::Class
    Exception::Class->import(
      $err_class => {
        isa => $parent,
        (defined $description ? (description => $description) : ()),
        fields => [keys %{ $defaults{ $err_class } }],
      }
    );

    return;
}
push @EXPORT_OK, "declare_err";

########################################################################
# code below here is to support compile time checking (technically
# "CHECK" time checking) that exceptions have been properly declared when
# they're referenced in is_err and throw_err.
#
# None of it will be checked if B::CallChecker is not installed (but the
# code will still function okay)
########################################################################

if (eval "use B::CallChecker; 1") {

   ########################################################################
   # routine to work out if a code has previously been declared or not
   ########################################################################

    my %classes_we_have_declared;

    sub _is_code_declared {
        my $err_class = _class_from_code(shift);

        # has this been declared with a declare_err call?
        return 1 if $classes_we_have_declared{ $err_class };

        # no? well, there's still a chance that someone has
        # declared it manually! We should check isa (note, we can't
        # *just* check isa because it's entirely possible that someone
        # has correctly used a declare_err to declare this code
        # but that declare_err statement hasn't been executed yet
        # (because code_is_declared is being called at CHECK time)
        # in which case the code will have been registered but the
        # @ISA will not have been setup at that point)
        return $err_class->isa("Exception::Class::Base");
    }

    ########################################################################
    # wrapping throw_err, is_err, ex_is_err
    ########################################################################

    foreach my $subname (qw(throw_err is_err ex_is_err)) {
        my $uboat = do {
            no strict 'refs';
            \&{ $subname };
        };

        # remember what the normal checking routine would do
        my ($original_check, $data) = B::CallChecker::cv_get_call_checker($uboat);

        # install our own checker that doesn't actually do prototype
        # checking but instead interrogates the first argument to see
        # if it's a valid exception code 
        B::CallChecker::cv_set_call_checker($uboat, sub {

            # extract the first argument
            my $const = $_[0]->first->first->sibling;

            # ignore it if it's not a constant.  We can't check this
            # at compile time, so skip the check
            unless ($const->name eq "const") {
                croak "Improper use of $subname.  The first argument to $subname was not a constant string";
            }

            # get the value of the constant
            my $code = ${ $const->sv->object_2svref };

            # throw a compile time error if the code
            # hasn't been declared yet at compile time
            unless (_is_code_declared($code)) {
                croak "Undeclared exception code $code used in $subname (you must declare exception classes before referencing them)";
            }

            # return the results of making the normal check
            return $original_check->(@_);
        },$data);
    }

    ########################################################################
    # declare_err wrapping
    ########################################################################

    my $uboat = \&declare_err;

    # remember what the normal checking routine would do
    my ($original_check, $data) = B::CallChecker::cv_get_call_checker($uboat);

    # install our own checker that doesn't actually do prototype
    # checking but instead interrogates the first argument to
    # get the check
    B::CallChecker::cv_set_call_checker($uboat, sub {

        # extract the first argument
        my $const = $_[0]->first->first->sibling;

        # ignore it if it's not a constant.  We can't check this
        # at compile time, so skip the check
        unless ($const->name eq "const") {
            croak "Improper use of declare_err.  The first argument to declare_err was not a constant string";
        }

        # get the value of the constant
        my $code = ${ $const->sv->object_2svref };
        $classes_we_have_declared{ _class_from_code($code) } = 1;

        # return the results of making the normal check
        return $original_check->(@_);
    },$data);
}

########################################################################

1;

__END__

=head1 NAME

Err - Easily declare, throw and match exception objects

=head1 SYNOPSIS

  use Err qw(declare_err throw_err is_err);

  ### create a bunch of exception classes ###

  # this makes Err::Exception::Starship, subclass of Err::Exception
  # (which itself is a subclass of Exception::Class::Basee)
  declare_err ".Starship"
    description => "The space ship is broken.";

  # this makes Err::Exception::Starship::WarpDrive
  # subclass of Err::Exception::Starship
  declare_err ".Starship.WarpDrive"
    description => "The warp drive is broken.  We can't go FTL.";

  ### throw and catch errors ###

  use Try::Tiny;
  try {
    throw_err ".Starship.WarpDrive", "Have ejected warp core!"
      if $have_ejected_the_warp_core;
    go_to_warp_speed();
  } catch {
    if (is_err ".Starship") {
      call_scotty(); return
    }
    die $_;
  }

=head1 DESCRIPTION

B<WARNING: This is an alpha release and the interface and functionailty
may change without notice in future releases.  A non-alpha 1.0 release will
be released to the CPAN on or before August 1st, 2012.>

The module allows you to easily declare, throw and match exceptions.  It's
further syntatic sugar for Exception::Class.  It doesn't provide a try/catch
syntax but instead is designed to work well with plain old evals, Try::Tiny,
TryCatch, etc.

=head2 Functions

These module exports functions on demand, or you can call them fully qualified.

=over

=item declare_err EXCEPTION_CODE, @optinal_args

Easy declarative syntax for defining exception class. EXCEPTION_CODE
must be a literal quoted string. See  L</Declaring Exceptions> below for more
details.

=item throw_err EXCEPTION_CODE, $message, @optional_args

Throws the exception with the attached message. EXCEPTION_CODE must be a literal
quoted string. See L<Throwing Exceptions> below for more details.

=item is_err EXCEPTION_CODE

=item ex_is_err EXCEPTION_CODE

Functions to examine C<$_> and C<$@> respectively for exception objects.
EXCEPTION_CODE must be a literal quoted string.  See L</Matching Exceptions>
below for more details.

=back

=head2 Understanding Exception Codes

An exception code is a brief form of the exception classname.  They're provided
as a way to visually distinguish exception classes from your normal class
hierarchy.

The rules to compute a class name from an exception code are blindingly simple:

=over

=item Replace any leading dot with C<Err::Exception::>

=item Replace any other dot with C<::>

=back

For example, the code C<.Starship> refers to the C<Err::Exception::Starship>
class.  The C<Err::Exception::Aliens::Klingons> class has the code
C<Aliens.Klingons>.  The C<Something.Else> code (no leading dot) refers to the
C<Something::Else>.

As a special case the code C<> refers to anything that is a subclass of 
C<Exception::Class::Base> itself, and C<.> refers to anything that is a
subclass of C<Err::Exception>.

If you don't like the exception code syntax you should note that under the above
rules any valid class name will function as a valid exception code.  (so for
example the exception code C<Foo::Bar> is the identical class name C<Foo::Bar>.)

=head2 Declaring Exceptions

Exceptions are declared with the C<declare_err> syntax.

In the simpliest form

=over

=item isa => $exception_code

Explicitly set the superclass of the exception by passing in the exception
code of the parent class.  This isn't often needed, since by default
C<declare_err> will simply set the class to be the natural parent of the
class (the class that's derived from removing the last ::Whatever from the
classname or, if the exception's classname is singular, Err::Exception.)

=item description => $description

Set the description of this class to give a human readable description of this
error that is applicable to all exceptions thrown of this class.

=item anything_else => $some_value

This becomes a new field in your exception object and provides a I<default
value> that C<throw_err> will populate the exception with when exceptions are
thrown.

=back

So, writing:

   declare_err ".Foo.Bar.Baz";

Is the same as writing

   use Exception::Class {
      "Err::Exception::Foo::Bar::Baz" => {
         isa => "Err::Exception::Foo::Bar",
      },
   }

And

   declare_err ".Foo.Bar.Buzz";
      isa => ".Onomatopoeia",
      description => "*Bzzz* that's wrong",
      volume => 11;

Is almost the same as writing

   use Exception::Class {
      "Err::Exception::Foo::Bar::Buzz" => {
         isa => "Err::Exception::Onomatopoeia",
         fields => ["volume"]
      },
   }

And then remembering always to do

   Err::Exception::Foo::Bar::Buzz->throw( volume => 11 );

When you throw it if you don't have an alternative volume to pass in.

=head2 Throwing Exceptions

Exceptions can be thrown with the C<throw_err> keyword.  This keyword takes the
code for the exception followed by an error message as it's arguments, and
essentially constructs a new instance of the exception and then throws it.  In
other words:

  throw_err ".Starship", "Self destruct sequence activated!";

Is the the same as:

  Err::Exception::Starship->throw(
    message => "Self destruct sequence activated "
  );

You can also pass other name value pairs after the message, that will be
passed through to the 

  throw_err ".Foo.Bar.Buzz", "Time's up", volume => 4;

These will be passed to Exception::Class::Base's throw method, meaning the
above is the same as:

  Err::Exception::Foo::Bar::Buzz->throw(
    message => "Time's up",
    volume => 4,
  );

=head2 Match Exceptions

The C<is_err> and C<ex_is_err> can be used to check if C<$_> or C<$@>
contain exceptions.

With plain old eval:

  eval {
    throw ".Starship.Holodeck", "Morarity has become sentient!";
  };
  if (ex_is_err(".Starship.Holodeck")) {
    get_picard_to_reason_with_him();
  } elsif ($@) { die }

With Try::Tiny

  try {
    throw ".Starship.Holodeck", "Morarity has become sentient!";
  } catch {
      if (is_err(".Starship.Holodeck")) {
        get_picard_to_reason_with_him();
        return;
      }
      die $_;
  };

With TryCatch

  try {
    throw ".Starship.Holodeck", "Morarity has become sentient!";
  } catch ($e where { is_err(".StarShip.Holodeck") }) {
    get_picard_to_reason_with_him();
  }

=head2 Enforced Declaring of Exceptions Before Use

If you have the B::CallChecker module installed (and I highly recommend you
do) this module will check B<at compile time> that the exceptions you
throw and match with C<throw_err>, C<is_err> and C<ex_is_err> have been declared
first.  If you have not declared your exception class in at the point in your
code where it's used Perl will not compile your class.

For those of you that are interested, this is achieved by hooking the CHECK
routine for these functions (and, for that matter C<declare_err> too) and
interspecing the OP tree to extract the first argument to them so we can
check if it's been declared first.  But you don't need to know that to use
this module - it's all magic.

If you don't have B::CallChecker installed you lose this checking functionality
but your exception classes will otherwise remain fully functional.

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT

Copyright OmniTI 2012.  All Rights Rerserved.

Copyright Mark Fowler 2012.  All Rights Rerserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.  This module has a 100% test coverage (branch, statement and
pod.)

Bugs (or feature requests) should be reported via this distribution's
CPAN RT queue.  This can be found at
L<https://rt.cpan.org/Dist/Display.html?Err>

You can also address issues by forking this distribution
on github and sending pull requests.  It can be found at
L<http://github.com/2shortplanks/Err>

=head1 SEE ALSO

L<Exception::Class> - syntax for declaring, throwing and matching Err::Exception objects.

L<Try::Tiny> - simple improved try/catch syntax with little dependancies

L<TryCatch> - powerful dependancy heavy improved try/catch syntax

=cut

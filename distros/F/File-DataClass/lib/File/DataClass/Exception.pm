package File::DataClass::Exception;

use namespace::autoclean;

use Unexpected::Functions qw( has_exception );
use Unexpected::Types     qw( Str );
use Moo;

extends q(Unexpected);
with    q(Unexpected::TraitFor::ErrorLeader);
with    q(Unexpected::TraitFor::ExceptionClasses);

my $class = __PACKAGE__; $class->ignore_class( 'File::DataClass::IO' );

has_exception $class;

has_exception 'NothingUpdated' => parents => [ $class ],
   error   => 'Nothing updated';

has_exception 'PathAlreadyExists' => parents => [ $class ],
   error   => 'Path [_1] already exists';

has_exception 'PathNotFound' => parents => [ $class ],
   error   => 'Path [_1] not found';

has_exception 'InvocantUndefined' => parents => [ $class ],
   error   => 'Method [_1] cannot call with undefined invocant';

has_exception 'RecordAlreadyExists' => parents => [ $class ],
   error   => 'File [_1] record [_2] already exists';

has_exception 'RecordNotFound' => parents => [ $class ],
   error   => 'File [_1] record [_2] does not exist';

has '+class' => default => $class;

has 'out'    => is => 'ro', isa => Str, default => q();

1;

__END__

=pod

=encoding utf-8

=head1 Name

File::DataClass::Exception - Exception class composed from traits

=head1 Synopsis

   use File::DataClass::Functions qw( throw );
   use Try::Tiny;

   sub some_method {
      my $self = shift;

      try   { this_will_fail }
      catch { throw $_ };
   }

   # OR
   use File::DataClass::Exception;

   sub some_method {
      my $self = shift;

      eval { this_will_fail };
      File::DataClass::Exception->throw_on_error;
   }

   # THEN
   try   { $self->some_method() }
   catch { warn $_."\n\n".$_->stacktrace."\n" };

=head1 Description

An exception class that supports error messages with placeholders, a
L<File::DataClass::Exception::TraitFor::Throwing/throw> method with
automatic re-throw upon detection of self, conditional throw if an
exception was caught and a simplified stacktrace

Applies exception roles to the exception base class L<Unexpected>. See
L</Dependencies> for the list of roles that are applied

Error objects are overloaded to stringify to the full error message
plus a leader if the optional C<ErrorLeader> role has been applied

=head1 Configuration and Environment

Ignores L<File::DataClass::IO> when creating exception leaders

Defines these attributes;

=over 3

=item C<out>

A string containing the output from whatever was being called before
it threw

=back

=head1 Subroutines/Methods

=head2 BUILDARGS

Doesn't modify the C<BUILDARGS> method. This is here to workaround a
bug in L<Moo> and / or L<Test::Pod::Coverage>

=head2 as_string

   $printable_string = $e->as_string

What an instance of this class stringifies to

=head2 caught

   $e = File::DataClass::Exception->caught( $error );

Catches and returns a thrown exception or generates a new exception if
C<EVAL_ERROR> has been set or if an error string was passed in

=head2 clone

   $clone = $e->clone;

Returns a clone of the exception object

=head2 stacktrace

   $lines = $e->stacktrace( $num_lines_to_skip );

Return the stack trace. Defaults to skipping zero lines of output
Skips anonymous stack frames, minimalist

=head2 throw

   File::DataClass::Exception->throw( $error );

Create (or re-throw) an exception to be caught by the L</caught> method. If
the passed parameter is a reference it is re-thrown. If a single scalar
is passed it is taken to be an error message code, a new exception is
created with all other parameters taking their default values. If more
than one parameter is passed the it is treated as a list and used to
instantiate the new exception. The C<error> attribute must be provided
in this case

=head2 throw_on_error

   File::DataClass::Exception->throw_on_error( $error );

Calls L</caught> and if the was an exception L</throw>s it

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<namespace::autoclean>

=item L<Moo>

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

L<Throwable::Error> - Lifted the stack frame filter from here

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:

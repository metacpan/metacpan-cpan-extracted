package File::DataClass::Types;

use strict;
use warnings;

use File::DataClass::IO   qw( io );
use Scalar::Util          qw( blessed dualvar );
use Type::Library             -base, -declare =>
                          qw( Cache DummyClass HashRefOfBools Lock
                              OctalNum Result Path Directory File );
use Type::Utils           qw( as coerce extends from
                              message subtype via where );
use Unexpected::Functions qw( inflate_message );

use namespace::clean -except => 'meta';

BEGIN { extends q(Unexpected::Types) };

# Private functions
my $_coercion_for_octalnum = sub {
   my $x = shift; length $x or return $x;

   $x =~ m{ [^0-7] }mx and return $x; $x =~ s{ \A 0 }{}gmx;

   return dualvar oct "${x}", "0${x}"
};

my $_constraint_for_octalnum = sub {
   my $x = shift; length $x or return 0;

   $x =~ m{ [^0-7] }mx and return 0;

   return ($x < 8) || (oct "${x}" == $x + 0) ? 1 : 0;
};

my $_exception_message_for_object_reference = sub {
   return inflate_message( 'String [_1] is not an object reference', $_[ 0 ] );
};

my $_exception_message_for_cache = sub {
   blessed $_[ 0 ] and return inflate_message
      ( 'Object [_1] is not of class File::DataClass::Cache', blessed $_[ 0 ] );

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

my $_exception_message_for_lock = sub {
   blessed $_[ 0 ] and return inflate_message
      ( 'Object [_1] is missing set / reset methods', blessed $_[ 0 ] );

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

my $_exception_message_for_path = sub {
   blessed $_[ 0 ] and return inflate_message
      ( 'Object [_1] is not of class File::DataClass::IO', blessed $_[ 0 ] );

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

my $_exception_message_for_result = sub {
   blessed $_[ 0 ] and return inflate_message
      ( 'Object [_1] is not of class File::DataClass::Result', blessed $_[ 0 ]);

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

subtype Cache, as Object,
   where   { $_->isa( 'File::DataClass::Cache' ) or $_->isa( 'Class::Null' ) },
   message { $_exception_message_for_cache->( $_ ) };

subtype DummyClass, as Str,
   where   { $_ eq 'none' },
   message { inflate_message( 'Dummy class [_1] is not "none"', $_ ) };

subtype HashRefOfBools, as HashRef;

subtype Lock, as Object,
   where   { ($_->can( 'set' ) and $_->can( 'reset' ) )
                                or $_->isa( 'Class::Null' ) },
   message { $_exception_message_for_lock->( $_ ) };

subtype OctalNum, as Str,
   where   { $_constraint_for_octalnum->( $_ ) },
   message { inflate_message( 'String [_1] is not an octal number', $_ ) };

subtype Path, as Object,
   where   { $_->isa( 'File::DataClass::IO' ) },
   message { $_exception_message_for_path->( $_ ) };

subtype Result, as Object,
   where   { $_->isa( 'File::DataClass::Result' ) },
   message { $_exception_message_for_result->( $_ ) };


subtype Directory, as Path,
   where   { $_->exists and $_->is_dir  },
   message { inflate_message( 'Path [_1] is not a directory', $_ ) };

subtype File, as Path,
   where   { $_->exists and $_->is_file },
   message { inflate_message( 'Path [_1] is not a file', $_ ) };

coerce HashRefOfBools, from ArrayRef,
   via { my %hash = map { $_ => 1 } @{ $_ }; return \%hash; };

coerce OctalNum, from Str, via { $_coercion_for_octalnum->( $_ ) };

coerce Directory,
   from ArrayRef, via { io( $_ ) },
   from CodeRef,  via { io( $_ ) },
   from HashRef,  via { io( $_ ) },
   from Str,      via { io( $_ ) },
   from Undef,    via { io( $_ ) };

coerce File,
   from ArrayRef, via { io( $_ ) },
   from CodeRef,  via { io( $_ ) },
   from HashRef,  via { io( $_ ) },
   from Str,      via { io( $_ ) },
   from Undef,    via { io( $_ ) };

coerce Path,
   from ArrayRef, via { io( $_ ) },
   from CodeRef,  via { io( $_ ) },
   from HashRef,  via { io( $_ ) },
   from Str,      via { io( $_ ) },
   from Undef,    via { io( $_ ) };

1;

__END__

=pod

=head1 Name

File::DataClass::Types - A type constraint library

=head1 Synopsis

   use Moo;
   use File::DataClass::Types qw( Path Directory File );

=head1 Description

Defines the type constraints used in this distribution

=head1 Configuration and Environment

Defines these subtypes

=over 3

=item C<Cache>

Is a L<File::DataClass::Cache>

=item C<DummyClass>

A string value 'none'

=item C<HashRefOfBools>

Coerces a hash ref of boolean true values from the keys in an array ref

=item C<Lock>

Is a L<Class::Null> or can C<set> and C<reset>

=item C<OctalNum>

Coerces a string to a number which is stored in octal

=item C<Path>

Is a L<File::DataClass::IO>. Can be coerced from either a string or
an array ref

=item C<Result>

Is a L<File::DataClass::Result>

=item C<Directory>

Subtype of C<Path> which is a directory. Can be coerced from
either a string or an array ref

=item C<File>

Subtype of C<Path> which is a file. Can be coerced from either a
string or an array ref

=back

=head1 Subroutines/Methods

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::DataClass::IO>

=item L<Type::Tiny>

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

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

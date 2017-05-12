package File::DataClass::Constants;

use strict;
use warnings;

use Exporter 5.57 qw( import );
use File::DataClass::Exception;

our @EXPORT = qw( ARRAY CODE CYGWIN EXCEPTION_CLASS FALSE HASH LANG
                  LOCALIZE LOCK_BLOCKING LOCK_NONBLOCKING MSOFT NO_UMASK_STACK
                  NUL PERMS SPC STAT_FIELDS STORAGE_BASE STORAGE_EXCEPTIONS
                  TILDE TRUE );

my $_exception_class = 'File::DataClass::Exception';

sub ARRAY    () { 'ARRAY'    }
sub CODE     () { 'CODE'     }
sub CYGWIN   () { 'cygwin'   }
sub FALSE    () { 0          }
sub HASH     () { 'HASH'     }
sub LANG     () { 'en'       }
sub LOCALIZE () { '[_'       }
sub MSOFT    () { 'mswin32'  }
sub NUL      () { q()        }
sub PERMS    () { oct '0640' }
sub SPC      () { ' '        }
sub TILDE    () { '~'        }
sub TRUE     () { 1          }

sub EXCEPTION_CLASS    () { __PACKAGE__->Exception_Class }
sub LOCK_BLOCKING      () { 1 }
sub LOCK_NONBLOCKING   () { 2 }
sub NO_UMASK_STACK     () { -1 }
sub STAT_FIELDS        () { qw( device inode mode nlink uid gid device_id
                                size atime mtime ctime blksize blocks ) }
sub STORAGE_BASE       () { 'File::DataClass::Storage' }
sub STORAGE_EXCEPTIONS () { 'File::DataClass::Storage::WithLanguage' }

sub Exception_Class {
   my ($self, $class) = @_; defined $class or return $_exception_class;

   $class->can( 'throw' )
       or die "Class '${class}' is not loaded or has no 'throw' method";

   return $_exception_class = $class;
}

1;

__END__

=pod

=head1 Name

File::DataClass::Constants - Definitions of constant values

=head1 Synopsis

   use File::DataClass::Constants;

   my $bool = TRUE;

=head1 Description

Exports a list of subroutines each of which returns a constants value

=head1 Subroutines/Methods

=head2 Exception_Class

Class method. An accessor / mutator for the classname returned by the
L</EXCEPTION_CLASS> function

=head2 C<ARRAY>

String ARRAY

=head2 C<CODE>

String CODE

=head2 C<CYGWIN>

The devil's spawn with compatibility library loaded

=head2 C<EXCEPTION_CLASS>

The class to use when throwing exceptions

=head2 C<FALSE>

Digit 0

=head2 C<HASH>

String HASH

=head2 C<LANG>

Default language code, C<en>

=head2 C<LOCALIZE>

The character sequence that introduces a localisation substitution
parameter. Left square bracket underscore

=head2 C<LOCK_BLOCKING>

Integer constant used to indicate a blocking lock call

=head2 C<LOCK_NONBLOCKING>

Integer constant used to indicate a non-blocking lock call

=head2 C<MSOFT>

The string C<MSWin32>

=head2 C<NO_UMASK_STACK>

Prevent the IO object from pushing and restoring umasks by pushing this
value onto the I<_umask> array ref attribute

=head2 C<NUL>

Empty string

=head2 C<PERMS>

Default file creation permissions

=head2 C<SPC>

Space character

=head2 C<STAT_FIELDS>

The list of fields returned by the core C<stat> function

=head2 C<STORAGE_BASE>

The prefix for storage classes

=head2 C<STORAGE_EXCEPTIONS>

Previous versions of L<File::DataClass> had some now incompatible
storage subclasses that may still be installed.  Listing them here
prevents them from inadvertently participating in the C<extension_map>
registration process

=head2 C<TILDE>

The (~) tilde character

=head2 C<TRUE>

Digit 1

=head1 Diagnostics

None

=head1 Configuration and Environment

None

=head1 Dependencies

=over 3

=item L<Exporter>

=item L<File::DataClass::Exception>

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

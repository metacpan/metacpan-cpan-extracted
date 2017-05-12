package IPC::SRLock::Constants;

use strict;
use warnings;
use parent 'Exporter::Tiny';

use File::DataClass::Exception;

our @EXPORT_OK = qw( EXCEPTION_CLASS );

my $_exception_class = 'File::DataClass::Exception';

sub EXCEPTION_CLASS () { __PACKAGE__->Exception_Class }

sub Exception_Class {
   my ($self, $class) = @_; defined $class or return $_exception_class;

   $class->can( 'throw' )
       or die "Class '${class}' is not loaded or has no 'throw' method";

   return $_exception_class = $class;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

IPC::SRLock::Constants - Defines constants used in this distribution

=head1 Synopsis

   use IPC::SRLock::Constants qw( EXCEPTION_CLASS );

=head1 Description

Defines constants used in this distribution

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 Exception_Class

Class method. An accessor / mutator for the classname returned by the
L</EXCEPTION_CLASS> function

=head2 C<EXCEPTION_CLASS>

The class to use when throwing exceptions

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Exporter>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPC-SRLock.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

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
# vim: expandtab shiftwidth=3:

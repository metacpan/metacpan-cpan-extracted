package Exception::Cxx;
require DynaLoader;
$VERSION = '1.001';
@ISA = 'DynaLoader';
__PACKAGE__->bootstrap($VERSION);

1;
__END__

=head1 NAME

  Exception::Cxx - Switch to ANSI C++ exceptions

=head1 SYNOPSIS

  use Exception::Cxx;

=head1 DESCRIPTION

This module arranges for perl to use ANSI C++ exceptions (instead of
C<setjmp>/C<longjmp>).  The reason you might want this is for
integration with 3rd party libraries that use C++ exceptions and
cannot switch back to C<longjmp>.

=head1 BUGS

C<sigsetjmp> saves more state than catch {}.  In C++, C<sigprocmask> &
C<priocntl> are not saved or restored.

C++ exceptions will not work with the CC perl compiler backend.
IMO, this is a bug in the backend.

=head1 CONTACT

If you have suggestions or more hints files, please contact me at
bitset@mindspring.com.  Thanks!

=head1 AUTHOR

Copyright © 1997-1999 Joshua Nathaniel Pritikin.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

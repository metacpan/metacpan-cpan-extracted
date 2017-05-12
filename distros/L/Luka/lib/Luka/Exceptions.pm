# $Id: Exceptions.pm,v 1.4 2006/02/27 21:43:59 toni Exp $
package Luka::Exceptions;

$VERSION = "1.02";

=head1 NAME

Luka::Exceptions - exception classes

=head1 SYNOPSIS

    use Luka::Exceptions;
    use Error qw(:try);
    push @Exception::Class::Base::ISA, 'Error'
        unless Exception::Class::Base->isa('Error');

    try {
        # some external library that dies unexpectedly
	do_something();
    }
    catch Error with {
        # this will catch errors of any type
        $e = shift;
        throw Luka::Exception::Program( error => $e, show_trace => 1 );
    };

=head1 DESCRIPTION

This class provides custom exceptions for Luka.

=head1 EXCEPTION types

There are three exceptions that can be thrown:

=over

=item Luka::Exception::External

network and OS errors (connectivity, file system);

=item Luka::Exception::User

user interaction related errors

=item Luka::Exception::Program

internal program errors

=back

=head1 EXCEPTION attributes

All classes have the same fields: error, context, args, path,
severity, conf, show_trace.

=head2 error

Error string thrown by library, in perl I<$!> or I<$@>.

=head2 context

Explanation of exception that ought to out error in context for the
person dealing with it who doesn't necessarily know much about the
script. For example, if an FTP connection fails we should report:

    FTP error: geting SpecialData feed from Someone failed.

and not anything similar to:
 
    FTP connection failed.

Why? Because to someone dealing with the problem, but not familiar
with the application, FTP connection failed says nothing new - usualy,
that info is already present in the library error, which should always
be in the I<error> field of the exception thrown. So, instead of
replicating information provided by the machine, give information
known only to you, developer:

=over

=item object/component dealt with

=item desired outcome and its importance of its functionality

=item remote side involved

=back

=head2 args

Arguments that might be needed for resolving the reasons for failure:
either those provided to the subroutine from which exception is thrown
or those supplied to the external library whose error we're dealing
with.

=head2 show_trace

If assigned value 1, this option will include stack trace.

=head2 severity

Severity level of the error thrown. See TODO section in L<Luka>.

=head2 id

Id of the error thrown. Can be used as a namespace for tracking errors
and linking to appropriate documentation.

=head2 conf

Configuration used for L<Luka> system. Used for testing only.

=head1 SEE ALSO

L<Exception::Class>, L<Luka>

=cut

BEGIN { $Exception::Class::BASE_EXC_CLASS = 'Luka::ExceptionBase'; }

use Exception::Class (  Luka::Exception,
			    Luka::Exception::External =>
			    {  
			        isa => 'Luka::Exception',
			        description => 'external exception',
			        fields => [ 'id', 'context', 'args', 'path', 'severity', 'conf' ],
			     },
			     Luka::Exception::User =>
			     { 
			         isa => 'Luka::Exception',
			         description => 'user related exception',
			         fields => [ 'id', 'context', 'args', 'path', 'severity', 'conf' ],
			     },
			     Luka::Exception::Program =>
			     {
			         isa => 'Luka::Exception',
			         description => 'internal programming exception',
			         fields => [ 'id', 'context', 'args', 'path', 'severity' , 'conf'],
			     },
			);

1;


=head1 AUTHOR

Toni Prug <toni@irational.org>

=head1 COPYRIGHT

Copyright (c) 2006. Toni Prug. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

See L<http://www.gnu.org/licenses/gpl.html>

=cut

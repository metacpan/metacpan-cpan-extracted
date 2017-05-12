#!/usr/bin/perl

package Mail::Log::Exceptions;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '1.0200';
use Exception::Class ( 	'Mail::Log::Exceptions'
						=> { description => 'A generic Mail::Log::Exception.'}
						,
						
						'Mail::Log::Exceptions::InvalidParameter'
						=> { description => 'A parameter that was passed to a method is invalid.'
								, isa => 'Mail::Log::Exceptions'
							},
						
						'Mail::Log::Exceptions::Unimplemented'
						=> { description => 'Stuff that should be implemented by subclasses.'
								, isa => 'Mail::Log::Exceptions'
							},
						
						'Mail::Log::Exceptions::LogFile'
						=> { description => 'An error with the logfile.'
								, isa => 'Mail::Log::Exceptions'
							},
						
						'Mail::Log::Exceptions::Message'
						=> { description => 'An error with the message info.'
								, isa => 'Mail::Log::Exceptions'
							},
						
						'Mail::Log::Exceptions::Message::IncompleteLog'
						=> { description => 'Message was not fully in this log.'
								, isa => 'Mail::Log::Exceptions::Message'
							},
						);


1;


=head1 NAME

Mail::Log::Exceptions - Exceptions for the Mail::Log::* modules.

=head1 SYNOPSIS

  use Mail::Log::Exceptions;

  Mail::Log::Exceptions->throw(q{Error description});

=head1 DESCRIPTION

This is a generic Exceptions module, supporting exceptions for the Mail::Log::*
modules.  At the moment it's just a thin wrapper around L<Exception::Class>, 
with appropriate class names for this use.

Current exceptions in this module:

=over 4

=item Mail::Log::Exceptions

The root level Exception class.  Generic: Avoid using.

=item Mail::Log::Exceptions::InvalidParameter

Errors due to passing the data types, not passing required data, or other
mistakes in calling method.

=item Mail::Log::Exceptions::Unimplemented

Exception to be thrown when a called method has not been implimented.  Typically
used by base classes when defining a method for subclasses to override.

=item Mail::Log::Exceptions::Logfile

Errors having to do with the logfile itself: Errors opening, reading, etc.

=item Mail::Log::Exceptions::Message

Errors having to do with message information: Something is unreadable, or
missing, or in bad format, etc.

=item Mail::Log::Exceptions::Message::IncompleteLog

Errors due to there being a logfile that is incomplete, or a message that is not
entirely within this logfile.

=back

Classes in the module tree may define sub-classes of the above exceptions.

=head1 USAGE

See L<Exception::Class>

=head1 REQUIRES

L<Exception::Class>

=head1 AUTHOR

Daniel T. Staal

DStaal@usa.net

=head1 SEE ALSO

L<Exception::Class>

=head1 HISTORY

Nov 22, 2008 - Added 

Oct 9, 2008 - Inital version.

=head1 COPYRIGHT and LICENSE

Copyright (c) 2008 Daniel T. Staal. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This copyright will expire in 30 years, or 5 years after the author's
death, whichever is longer.

=cut

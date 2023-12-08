package IO::FD::DWIM;
use strict;
use warnings;

use IO::FD;
use Export::These  qw<

	socket
	socketpair
	shutdown
	bind
	listen
	accept
	connect
	getsockopt
	setsockopt
 	getpeername
	getsockname

	sysopen
	sysseek

	pipe

	close
	recv
	send

	sysread
	syswrite

	stat
	lstat



	fcntl
	ioctl

	readline
	fileno
>;



#SOCKETS
sub socket :prototype($$$$) 
	{ref($_[0]) ? &CORE::socket : &IO::FD::socket; }

sub socketpair:prototype($$$$$) 
	{ref($_[0]) ? &CORE::socketpair : &IO::FD::socketpair; }

sub shutdown:prototype($$)
	{ref($_[0]) ? &CORE::shutdown : &IO::FD::shutdown; }

sub bind:prototype($$) 
	{ref($_[0]) ? &CORE::bind : &IO::FD::bind; }

sub listen:prototype($$) 
	{ref($_[0]) ? &CORE::listen : &IO::FD::listen; }

sub accept:prototype($$) 
	{ref($_[0]) ? &CORE::accept : &IO::FD::accept; }

sub connect:prototype($$) 
	{ref($_[0]) ? &CORE::connect : &IO::FD::connect; }

sub getsockopt:prototype($$$) 
	{ref($_[0]) ? &CORE::getsockopt : &IO::FD::getsockopt; }

sub setsockopt:prototype($$$$) 
	{ref($_[0]) ? &CORE::setsockopt : &IO::FD::setsockopt; }

sub getpeername:prototype($) 
	{ref($_[0]) ? &CORE::getpeername : &IO::FD::getpeername; }

sub getsockname:prototype($) 
	{ref($_[0]) ? &CORE::getsockname : &IO::FD::getsockname; }

#FILES

sub sysopen:prototype($$$@) 
	{ref($_[0]) ? &CORE::sysopen : &IO::FD::sysopen; }

sub sysseek:prototype($$$) 
	{ref($_[0]) ? &CORE::sysseek : &IO::FD::sysseek; }

#PIPE

sub pipe:prototype($$) 
	{ref($_[0]) ? &CORE::pipe : &IO::FD::pipe; }



#COMMON

sub close($) 
	{ref($_[0]) ? &CORE::close : &IO::FD::close; }

sub recv:prototype($$$$) 
	{ref($_[0]) ? &CORE::recv : &IO::FD::recv; }

sub send:prototype($$$@) 
	{ref($_[0]) ? &CORE::send : &IO::FD::send; }


sub sysread:prototype($\$$@) 
	{ref($_[0]) ? &CORE::sysread : &IO::FD::sysread; }

sub syswrite:prototype($$@) 
	{ref($_[0]) ? &CORE::syswrite : &IO::FD::syswrite; }


sub stat($) 
	{ref($_[0]) ? &CORE::stat : &IO::FD::stat; }

sub lstat($) 
	{ref($_[0]) ? &CORE::lstat : &IO::FD::lstat; }

sub fcntl:prototype($$$) 
	{ref($_[0]) ? &CORE::fcntl : &IO::FD::fcntl; }

sub ioctl:prototype($$$) 
	{ref($_[0]) ? &CORE::ioctl : &IO::FD::ioctl; }

sub readline($) 
	{ref($_[0]) ? &CORE::readline : &IO::FD::readline; }

sub fileno :prototype($) {
	ref($_[0])
		?fileno $_[0]
		: $_[0];
}
1;
__END__

=head1 NAME

IO::FD::DWIM - Mixed file handle/descriptor functions

=head1 SYNOPSIS

	use IO::FD::DWIM ":all";

	sysopen (my $f, ">test.txt");

	syswrite $f, "hello!";

=head1 DESCRIPTION

Using this modules will overwrite the Perl routines of the same name. The new
routines will work with either Perl file handles or integer fds via L<IO::FD>.

If the first argument to these functions look like a reference, then they are
assumed to be Perl file handles. In this case the CORE:: version of the function
will be called with the same parameters.

Otherwise, they are assumed to be integer file descriptor values and the
corresponding IO::FD function will be called with the same parameters.


Special variables and syntax (i.e '_' for stat and <> for readline) will not work
with these functions.

The goal of this module is to allow easy switch over from file handles to file
descriptors for networking code.

=head1 API

The following functions are imported into the current
package:

	socket
	socketpair
	bind
	listen
	accept
	connect
	getsockopt
	setsockopt
 	getpeername
	getsockname
	sysopen
	sysseek
	pipe
	close
	recv
	send
	sysread
	syswrite
	stat
	lstat
	fcntl
	ioctl
	readline
	fileno

=head1 AUTHOR

Ruben Westerberg, E<lt>drclaw@mac.comE<gt>

=head1 REPOSITORTY and BUGS

This module is part of the L<IO::FD> distribution.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Ruben Westerberg

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl or the MIT
license.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE.
=cut

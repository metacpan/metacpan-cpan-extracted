# $Id: Compat.pm,v 1.3 2009/01/08 15:33:04 dk Exp $
use strict;

package IO::Lambda::Compat;

use strict;
use warnings;

use Exporter;
use IO::Lambda qw(:all :dev);
use vars qw(@ISA @EXPORT);
@ISA    = qw(Exporter);
@EXPORT = qw(read write sleep readwrite predicate);

# readwrite($flags,$handle,$deadline)
sub readwrite(&)
{
	return this-> override_handler('readwrite', \&readwrite, shift)
		if this-> {override}->{readwrite};

	my @c = context;
	this-> add_watch( 
		_subname(readwrite => shift), \&readwrite,
		@c[0,1,2,0,1,2]
	)
}

# read($handle,$deadline)
sub read(&)
{
	return this-> override_handler('read', \&read, shift)
		if this-> {override}->{read};

	my @c = context;
	this-> add_watch( 
		_subname(read => shift), \&read, IO_READ, 
		@c[0,1,0,1]
	)
}

# handle($handle,$deadline)
sub write(&)
{
	return this-> override_handler('write', \&write, shift)
		if this-> {override}->{write};
	my @c = context;
	this-> add_watch( 
		_subname(write => shift), \&write, IO_WRITE, 
		@c[0,1,0,1]
	)
}

# sleep($deadline)
sub sleep(&)
{
	return this-> override_handler('sleep', \&sleep, shift)
		if this-> {override}->{sleep};
	my @c = context;
	this-> add_timer( _subname(sleep => shift), \&sleep, @c[0,0])
}

*predicate = \&IO::Lambda::condition;

1;

=head1 NAME

IO::Lambda::Compat - compatibility with pre-v1.00 version API

=head1 SYNOPSIS

   use IO::Lambda qw(:lambda);
   use IO::Lambda::Compat;

   lambda {
      context $socket;
      read { }
   }

=head1 DESCRIPTION

The module exports the following names, which were renamed in IO::Lambda
after version 1.01: read, write, sleep, readwrite, predicate.
Issue C<use IO::Lambda::Compat> to make older programs compatible with
the newer API.

=cut

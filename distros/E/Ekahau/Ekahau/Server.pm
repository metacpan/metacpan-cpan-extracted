package Ekahau::Server;
use base 'Ekahau::Base'; our $VERSION = $Ekahau::Base::VERSION;
use base 'Ekahau::ErrHandler';

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use warnings;
use strict;
use bytes;

=head1 NAME

Ekahau::Server - Simple class for creating an Ekahau-style server, for testing

=head1 SYNOPSIS

This class is used to create a server that behaves like the Ekahau
Positioning Engine.  It is only used for testing the Ekahau client,
via the L<Ekahau::Server::Test|Ekahau::Server::Test> class.

Because this class is used only for testing, it is not documented.

=cut

use constant READ_BLOCKSIZE => 8192;
use constant DEFAULT_TIMEOUT => 10;

use IO::Select;

sub new
{
    my $class = shift;
    my(%p) = @_;
    my $private_error;

    my $self = {};
    bless $self, $class;
    $self->{_errhandler} = Ekahau::ErrHandler->errhandler_new($class,%p);

    $self->{tag} = 0;
    $self->{_readbuf} = "";
    $self->{_timeout}=$p{Timeout}||$p{timeout}||DEFAULT_TIMEOUT;
    
    $self->{_sock} = $p{Socket}
      or return $self->reterr("No Socket supplied to Ekahau::Server constructor.\n");
    binmode $self->{_sock};
    $self->{_sock}->autoflush(1);
    $self->{_socksel} = IO::Select->new($self->{_sock})
	or return $self->reterr("Couldn't create IO::Select object: $!\n");

    $self->errhandler_constructed();
}

sub ERROBJ
{
    my $self = shift;
    $self->{_errhandler};
}

sub nextresponse
{
    my $self = shift;
    my($sock)=@_;

    my $resp = $self->SUPER::nextresponse
	or return undef;
    $resp;
}

sub reply
{
    my $self = shift;
    my $resp = shift;
    $self->command(@_,$resp->{tag});
}

sub DESTROY
{
    ;
}

package Ekahau::Server::Listener;
use base 'Ekahau::ErrHandler';

use constant DEFAULT_PORT => 8548;
use constant DEFAULT_HOST => 0;

sub new
{
    my $class = shift;
    my(%p) = @_;
    
    my $self = {};
    bless $self,$class;
    $self->{_errhandler} = Ekahau::ErrHandler->errhandler_new($class,%p);

    $self->{_timeout}=$p{Timeout}||$p{timeout}||Ekahau::Server::DEFAULT_TIMEOUT;
    
    $self->_opensock(%p)
	or return undef;

    $self->errhandler_constructed();
}

sub ERROBJ
{
    my $self = shift;
    $self->{_errhandler};
}

# Connect to the TCP socket
sub _opensock
{
    my $self = shift;
    my(%p)=@_;
    my $sock;

    if ($p{Socket})
    {
	$sock = $p{Socket};
    }
    else
    {
	# For IO::Socket::INET
	if ($p{timeout} && !$p{Timeout})
	{
	    $p{Timeout}=$p{timeout};
	}
	elsif ($self->{_timeout})
	{
	    $p{Timeout} = $self->{_timeout};
	}
	
	if (!$p{LocalPort}) { $p{LocalPort} = DEFAULT_PORT };
	if (!$p{LocalAddr} and !$p{LocalHost}) { $p{LocalAddr} = DEFAULT_HOST };
	
	warn "DEBUG Created listener for $p{LocalAddr}:$p{LocalPort}...\n"
	    if ($ENV{VERBOSE});
	$sock = IO::Socket::INET->new(%p,
				      Listen => 5,
				      ReuseAddr => 1,
				      Proto => 'tcp')
	    or return $self->reterr("Couldn't create IO::Socket::INET - $!");
    }

    $self->{_listen} = $sock;
    binmode $self->{_listen};
    $self->{_listen}->autoflush(1);

    warn "DEBUG connected.\n"
       if ($ENV{VERBOSE});
}

sub accept
{
    my $self = shift;
    my $class = shift || 'Ekahau::Server';
    my $newconn = $self->{_listen}->accept
	or return undef;
    return $class->new(Socket => $newconn,
		       Timeout => $self->{_timeout});
}

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut

1;

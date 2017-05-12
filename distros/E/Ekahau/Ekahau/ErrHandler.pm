package Ekahau::ErrHandler;
our $VERSION = '0.001';

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2005 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use warnings;
use strict;
use Carp;


=head1 NAME

Ekahau::ErrHandler - Internal class used to unify error handling across Ekahau modules

=head1 SYNOPSIS

This class provides consistent error-handling methods across all of
the Ekahau classes.  It is designed for internal use only, and so is
not documented.

=cut


use constant EHCLASS => 'Ekahau::ErrHandler';
use constant INTCLASS => EHCLASS.'::Internal';

sub errhandler_new
{
    my $class = shift;
    my($objclass,%p) = @_;
    $objclass 
	or croak "usage: Ekahau::ErrHandler->errhandler_new($class,[%params])";
    my $self = {objclass => $objclass};
    bless $self, 'Ekahau::ErrHandler::Internal';
    
    # If these are undef defaults will be set
    $self->set_errhandler($p{ErrorHandler});
    $self->set_errholder($p{ErrorHolder});

    $self;
}

sub errhandler_constructed
{
    my $self = shift;
    my $errobj = $self->ERROBJ
	or croak "Couldn't get error object from $self";
    $errobj->errhandler_constructed(@_);
    $self;
}

sub errhandler_deconstructed
{
    my $self = shift;
    my $errobj = $self->ERROBJ
	or croak "Couldn't get error object from $self";
    $errobj->errhandler_constructed(@_);
    $self;
}

sub set_errhandler
{
    my $self = shift;
    if (ref $self)
    {
	# Object
	my $errobj = $self->ERROBJ
	    or croak "Couldn't get error object from $self";
	return $errobj->set_errhandler(@_);
    } 
    else
    {
	return Ekahau::ErrHandler::Internal->class_errhandler($self,@_);
    }
}

sub set_errholder
{
    my $self = shift;
    if (ref $self)
    {
	# Object
	my $errobj = $self->ERROBJ
	    or croak "Couldn't get error object from $self";
	return $errobj->set_errholder(@_);
    }
    else
    {
	return Ekahau::ErrHandler::Internal->class_errholder($self,@_);
    }
}

sub reterr
{
    my $self = shift;
    my $errobj = $self->ERROBJ
	or croak "Couldn't get error object from $self";
    $errobj->reterr(@_);
}

sub lasterr
{
    my $arg = shift;
    if (ref $arg)
    {
	# Object
	my $errobj = $arg->ERROBJ
	    or croak "Couldn't get error object from '$arg'";
	return $errobj->lasterr(@_);
    }
    else
    {
	return Ekahau::ErrHandler::Internal->last_classerr($arg);
    }
}

# Alias for lasterr.
sub lasterror
{
    goto &lasterr;
}

package Ekahau::ErrHandler::Internal;

use constant EHCLASS => Ekahau::ErrHandler::EHCLASS;
use constant INTCLASS => Ekahau::ErrHandler::INTCLASS;

our %class_errstr;
our %classdefs;
our %defs;

sub errhandler_constructed
{
    my $self = shift;

    $self->{constructed} = 1;
    $self->set_errholder(undef)
	unless (!$self->{custom_errstr});
}

sub errhandler_deconstructed
{
    my $self = shift;

    $self->{constructed} = 0;
    $self->set_errholder(undef)
	unless (!$self->{custom_errstr});
}



sub set_errhandler
{
    my $self = shift;
    my($handler)=@_;
    
    if ($handler)
    {
	$self->{handler} = $handler;
	$self->{custom_handler} = 1;
    }
    else
    {
	if ($classdefs{$self->{objclass}} and $classdefs{$self->{objclass}}{handler})
	{
	    $self->{handler} = $classdefs{$self->{objclass}}{handler};
	}
	elsif ($classdefs{EHCLASS()} and $classdefs{EHCLASS()}{handler})
	{
	    $self->{handler} = $classdefs{EHCLASS()}{handler};
	}
	else
	{
	    $self->{handler} =\&default_errhandler;
	}
	$self->{custom_handler} = 0;
    }
}

sub set_errholder
{
    my $self = shift;
    my($holder)=@_;

    if ($holder)
    {
	$self->{errstr} = $holder;
	$self->{custom_errstr} = 1;
    }
    else
    {
	if ($self->{constructed})
	{
	    # Construct a lexical scalar
	    my $errstr = "unknown error";
	    $self->{errstr} = \$errstr;
	}
	else
	{
	    if (!$class_errstr{$self->{objclass}})
	    {
		my $errstr = "unknown error";
		$class_errstr{$self->{objclass}} = \$errstr;
	    }
	    $self->{errstr} = $class_errstr{$self->{objclass}};
	}
	    
	$self->{custom_errstr} = 0;
    }
}

sub reterr
{
    my $self = shift;
    
    $self->{handler}->($self,@_);
    undef;
}

sub lasterr
{
    my $self = shift;
    return ${$self->{errstr}};
}

sub last_classerr
{
    my $class = shift;
    my($objclass)=@_;
    return ${$class_errstr{$objclass}};
}

sub default_errhandler
{
    my $self = shift;
    my $errmsg = join("",@_);
    my $errholder = $self->{errstr};
    ref $errholder
      or die "Fatal error handling non-fatal error: $errmsg";
    $$errholder = $errmsg;
    1;
}

sub class_errholder
{
    my $class = shift;
    my($objclass,$holder)=@_;

    $classdefs{$objclass}{holder}=$holder;
}

sub class_errhandler
{
    my $class = shift;
    my($objclass,$handler)=@_;

    $classdefs{$objclass}{handler}=$handler;
}

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut


1;

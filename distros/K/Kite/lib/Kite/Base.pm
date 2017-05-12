#============================================================= -*-perl-*-
#
# Kite::Base
#
# DESCRIPTION
#   Base class module implementing common functionality.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2000 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# VERSION 
#   $Id: Base.pm,v 1.3 2000/10/17 11:58:16 abw Exp $
#
#========================================================================
 
package Kite::Base;

require 5.004;

use strict;
use vars qw( $VERSION $AUTOLOAD );

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);


#------------------------------------------------------------------------
# new(\%params)
#
# General purpose constructor method which expects a hash reference of 
# configuration parameters, or a list of name => value pairs which are 
# folded into a hash.  Blesses a hash into an object and calls its 
# _init() method, passing the parameter hash reference.  Returns a new
# object derived from Kite::Base, or undef on error.
#------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $params = (@_ && UNIVERSAL::isa($_[0], 'HASH')) ? shift : { @_ };
    my $self = bless { 
	_ERROR => '',
    }, $class;
    return $self->init($params) ? $self : $class->error($self->error);
}


#------------------------------------------------------------------------
# init()
#
# Initialisation method called by the new() constructor, passing a 
# reference to a hash array containing any configuration items specified
# as constructor arguments.  Should return $self on success or undef on 
# error, via a call to the error() method to set the error message.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my $class = ref $self;
    my $params;

    # get a reference to the $PARAMS hash in the derived class package
    {
	no strict qw( refs );
	$params = ${"$class\::PARAMS"};
    }

    if (defined $params) {
	# initialise the $self object from the $config hash passed, using
	# the $params hash to define acceptable parameters and defaults

	# map all config parameters to upper case
	@$config{ map { uc $_ } keys %$config } = values %$config;

	# read parameters into $self from $config, using defaults if undefined
	foreach my $key (keys %$params) {
	    if ($key =~ /^_/) {
		# just set default for private keys with leading _UNDERSCORE
		$self->{ $key } = $params->{ $key };
	    }
	    else {
		# otherwise use config value, if defined, or default
		$self->{ $key } = defined $config->{ $key } 
				  ? $config->{ $key } : $params->{ $key };
	    }
	}
    }
    
    return $self;
}


#------------------------------------------------------------------------
# error()
# error($msg, ...)
# 
# May be called as a class or object method to set or retrieve the 
# package variable $ERROR (class method) or internal member 
# $self->{ ERROR } (object method).  The presence of parameters indicates
# that the error value should be set.  Undef is then returned.  In the
# abscence of parameters, the current error value is returned.
#------------------------------------------------------------------------

sub error {
    my $self = shift;
    my $errvar;

    { 
	no strict qw( refs );
	$errvar = ref $self ? \$self->{ _ERROR } : \${"$self\::ERROR"};
    }
    if (@_) {
	$$errvar = join('', @_);
	return undef;
    }
    else {
	return $$errvar;
    }
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Autoload method.
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
    
    if ($method =~ /^_/) {
	my ($pkg, $file, $line) = caller();
	die "attempt to access private member $method at $file line $line\n";
    }

    $method = uc $method;
    if (@_) {
	return ($self->{ $method } = shift);
    }
    else {
	return $self->{ $method };
    }
}


#------------------------------------------------------------------------
# _dump()
#
# Debug method to return a formatted string containing the object data.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    my $text = "$self:\n";
    while (my ($key, $value) = each %$self) {
	$value = '<undef>' unless defined $value;
	$text .= sprintf("    %-12s => $value\n", $key);
    }
    return $text;
}


1;

__END__
	

=head1 NAME

Kite::Base - base class module implementing common functionality

=head1 SYNOPSIS

    package Kite::MyModule;

    use Kite::Base;
    use base qw( Kite::Base );
    use vars qw( $PARAMS $ERROR );

    $PARAMS = {
	TITLE => 'Default Title',
	ALPHA => 3.14,
	OMEGA => 2.718,
    };

    package main;
    
    # specify config as a hash reference...
    my $module = Kite::MyModule->new({
	TITLE => 'Grand Title',
	ALPHA => 3,
    }) || die $Kite::MyModule::ERROR, "\n";

    # ...or as a list of items;  parameter case is insignificant
    my $module = Kite::MyModule->new( TITLE => 'Grand Title' )
	|| die $Kite::MyModule::ERROR, "\n";
    
    print $module->title();
    print $module->alpha();
    print $module->omega();

=head1 DESCRIPTION

Base class module which implements a constructor and error reporting 
functionality for various Kite modules.

=head1 PUBLIC METHODS

=head2 new(\%config)

Constructor method which accepts a reference to a hash array or a list 
of C<name =E<gt> value> parameters which are folded into a hash.  The 
init() method is then called, passing the configuration hash and should
return true/false to indicate success or failure.  A new object reference
is returned, or undef on error.  Any error message raised can be examined
via the error() class method or directly via the package variable ERROR
in the derived class.

    package Kite::MyModule;

    use Kite::Base;
    use base qw( Kite::Base );

    package main;

    my $module1 = Kite::MyModule->new({ param => 'value' })
        || die Kite::MyModule->error(), "\n";

    my $module2 = Kite::MyModule->new( param => 'value' )
        || die "constructor error: $Kite::MyModule::ERROR\n";

=head2 init(\%config)

This method is called by the new() constructor to initialise the object.
A reference to a hash array of configuration items is passed as a parameter.

The method looks for a hash reference defined as the $PARAMS package variable
in the package of the derived class.  If defined, this hash array should 
contain keys which define the acceptable configuration paramaters and 
values which provide default values for that item.  The method then 
iterates through the items in this hash, copying any defined value in the
$config hash or otherwise the default value in the $PARAMS hash, into the
$self object.

All parameter names should be specified in the $PARAMS hash in UPPER CASE.
The user may specify UPPER or lower case parameters names and these will 
both be correctly handled.   Parameter names which are prefixed with an
underscore will be considered 'private'.  The default value, defined in the
$PARAMS hash will be copied into the $self object, but any value provided
in the $config hash will be ignored.

    package Kite::MyModule;

    use Kite::Base;
    use base qw( Kite::Base );    
    use vars qw( $ERROR $PARAMS );

    $PARAMS = {
	TITLE  => 'Default Title',
	AUTHOR => undef,		# no default
	_COUNT => 1,			# private variable
    };

    package main;
    
    my $mod = Kite::MyModule->new(title => 'The Title') 
	|| die $Kite::MyModule::ERROR;

Derived classes may elect to redefine the init() subroutine to provide 
their own custom initialisation routines.  They can, of course, explicitly
call the init() method on the parent class if they need to do so.

    package Kite::MyModule;

    ...

    sub init {
	my ($self, $config) = @_;
    
	$self->SUPER::init($config)
	    || return undef;

	# more configuration...

	return $self;
    }

=head2 error($msg)

May be called as an object method to get/set the internal _ERROR member
or as a class method to get/set the $ERROR variable in the derived class's
package.

    my $module = Kite::MyModule->new({ ... })
        || die Kite::MyModule->error(), "\n";

    $module->do_something() 
	|| die $module->error(), "\n";

When called with parameters (multiple params are concatenated), this
method will set the relevant variable and return undef.  This is most
often used within object methods to report errors to the caller.

    package Kite::MyModule;

    ...

    sub foobar {
	my $self = shift;
	...
	return $self->error('some kind of error...')
	    if $some_condition;
	...
    }

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 REVISION

$Revision: 1.3 $

=head1 COPYRIGHT

Copyright (C) 2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Kite|Kite>

=cut



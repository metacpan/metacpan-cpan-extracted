###########################################################################
#
# Java::SJ::VirtualMachine
#
# $Id: VirtualMachine.pm,v 1.3 2003/07/20 18:52:21 wiggly Exp $
#
# $Author: wiggly $
#
# $DateTime$
#
# $Revision: 1.3 $
#
###########################################################################

package Java::SJ::VirtualMachine;

use Carp;
use Data::Dumper;

our $VERSION = '0.01';

###########################################################################
#
# Constructor
#
###########################################################################
sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	# attributes
	$self->{'name'} = '';
	$self->{'vendor'} = '';
	$self->{'version'} = '';
	$self->{'language'} = '';
	$self->{'home'} = '';
	$self->{'default'} = '';
	$self->{'ref'} = '';

	# properties
	$self->{'prop'} = undef;

	# environment
	$self->{'env'} = undef;

	# environment
	$self->{'param'} = undef;

	#print STDERR "[DEBUG] VIRTUAL MACHINE\n" . Dumper( $self ) . "\n\n";
	return $self;		
}

###########################################################################
#
# name
#
###########################################################################
sub name
{
	my $self = shift;
	my $arg = shift;

	if( $arg )
	{
		$self->{'name'} = $arg;
	}

	$self->{'name'};
}

###########################################################################
#
# vendor
#
###########################################################################
sub vendor
{
	my $self = shift;
	my $arg = shift;

	if( $arg )
	{
		$self->{'vendor'} = $arg;
	}

	$self->{'vendor'};
}

###########################################################################
#
# version
#
###########################################################################
sub version
{
	my $self = shift;
	my $arg = shift;

	if( $arg )
	{
		$self->{'version'} = $arg;
	}

	$self->{'version'};	
}

###########################################################################
#
# language
#
###########################################################################
sub language
{
	my $self = shift;
	my $arg = shift;

	if( $arg )
	{
		$self->{'language'} = $arg;
	}

	$self->{'language'};
}

###########################################################################
#
# home
#
###########################################################################
sub home
{
	my $self = shift;
	my $arg = shift;

	if( $arg )
	{
		$self->{'home'} = $arg;
	}

	$self->{'home'};	
}

###########################################################################
#
# default
#
###########################################################################
sub default
{
	my $self = shift;
	my $arg = shift;

	if( $arg )
	{
		if( $arg =~ m/^(true|1|y|yes)$/i )
		{
			$self->{'default'} = 1;
		}
		else
		{
			$self->{'default'} = 0;
		}
	}

	$self->{'default'};	
}

###########################################################################
#
# ref
#
###########################################################################
sub ref
{
	my $self = shift;
	my $arg = shift;

	if( $arg )
	{
		$self->{'ref'} = $arg;
	}

	$self->{'ref'};
}

###########################################################################
#
# add_property
#
###########################################################################
sub add_property
{
	my $self = shift;
	my $name = shift;
	my $value = shift;
	$self->{'prop'}{$name} = $value;
	1;
}

###########################################################################
#
# add_environment
#
###########################################################################
sub add_environment
{
	my $self = shift;
	my $name = shift;
	my $value = shift;
	$self->{'env'}{$name} = $value;
	1;
}

###########################################################################
#
# add_param
#
###########################################################################
sub add_param
{
	my $self = shift;
	my $name = shift;
	my $value = shift;
	my $sep = shift;

	if( $sep =~ /^$/ )
	{
		$sep = ' ';
	}

	if( $value !~ /^$/ )
	{
		$self->{'param'}{$name} = $sep . $value;
	}
	else
	{
		$self->{'param'}{$name} = '';
	}
	1;
}




###########################################################################
1;

=pod

=head1 NAME

Java::SJ::VirtualMachine - Java virtual machine 

=head1 DESCRIPTION

This module is used by L<Java::SJ::Config> when generating virtual machine
representations.

=head1 TODO

Test, test, test.

=head1 BUGS

None known so far. Please report any and all to Nigel Rantor <F<wiggly@wiggly.org>>

=head1 SUPPORT / WARRANTY

This module is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 LICENSE

The Java::SJ::VirtualMachine module is Copyright (c) 2003 Nigel Rantor.
England. All rights reserved.

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the Perl README file.

=head1 AUTHORS

Nigel Rantor <F<wiggly@wiggly.org>>

=head1 SEE ALSO

L<Java::SJ>. L<Java::SJ::Config>.

=cut

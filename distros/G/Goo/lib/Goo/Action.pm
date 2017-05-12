package Goo::Action;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     GooAction.pm
# Description:  Remember an action in The Goo
#
# Date          Change
# -----------------------------------------------------------------------------
# 20/08/2005    Auto generated file
# 20/08/2005    Needed to pass around as an Object
#
###############################################################################

use strict;

use Goo::Object;

# GooAction isa Object
use base qw(Goo::Object);


###############################################################################
#
# new - construct a goo_action object
#
###############################################################################

sub new {

    my ($class, $params) = @_;

    my $this = $class->SUPER::new();

    # create a GooAction object
    $this->{actionid}   = $params->{actionid};
    $this->{action}     = $params->{action};
    $this->{who}        = $params->{who};
    $this->{thing}      = $params->{thing};
    $this->{actiontime} = $params->{actiontime};

    return $this;

}


###############################################################################
#
# get_action - return the description of the action performed
#
###############################################################################

sub get_action {

    my ($this) = @_;

	my $action = $this->{action};
	$action =~ s/\[//;
	$action =~ s/\]//;
    return $action;

}


###############################################################################
#
# get_user - who did the action?
#
###############################################################################

sub get_user {

    my ($this) = @_;

    return $this->{who};

}


###############################################################################
#
# get_when - when did they do the action?
#
###############################################################################

sub get_when {

    my ($this) = @_;

    return $this->{actiontime};

}


###############################################################################
#
# get_short_thing - what thing did they do the action on?
#
###############################################################################

sub get_short_thing {
	
	my ($this) = @_;
	
	my $short_thing = $this->{thing};

	$short_thing =~ s/.*\///;

	return $short_thing;

}


###############################################################################
#
# get_thing - what thing did they do the action on?
#
###############################################################################

sub get_thing {

    my ($this) = @_;

    return $this->{thing};

}


1;


__END__

=head1 NAME

Goo::Action - A Goo action

=head1 SYNOPSIS

use Goo::Action;

=head1 DESCRIPTION

Store who performed an action, when they did it, and to which Thing.

=head1 METHODS

=over

=item new

constructor

=item get_action

Return the description of the action performed

=item get_user

who did the action?

=item get_when

when did they do the action?

=item get_short_thing

eturn the short name of the Thing they did the action on?

=item get_thing

return the name and location of the Thing they did the action on?

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO


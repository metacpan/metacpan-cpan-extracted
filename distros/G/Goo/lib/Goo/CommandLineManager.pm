package Goo::CommandLineManager;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2004
# All Rights Reserved
#
# Author: 		Nigel Hamilton
# Filename:		Goo::CommandLineManager.pm
# Description: 	Manage command line parameters
#
# Date	 		Change
# -----------------------------------------------------------------------------
# 31/10/2004	Auto generated file
# 31/10/2004	Needed to reuse handling command lines
#
###############################################################################

use strict;
use Goo::Object;

use base qw(Goo::Object);


###############################################################################
#
# new - constructor
#
###############################################################################

sub new {

	my ($class, @parameters) = @_;

	my $this = $class->SUPER::new();

   	# the first parameter is the switch
    $this->{switch} 	= shift(@parameters);
    $this->{switch} 	=~ s/\-//g;
    $this->{parameters} = \@parameters;

	return $this;

}


###############################################################################
#
# get_last_parameter - pop off the last parameter
#
###############################################################################

sub get_last_parameter {
	
	my ($this) = @_;

	return pop @{ $this->{parameters} };
	
}


###############################################################################
#
# get_parameters - return all the parameters
#
###############################################################################

sub get_parameters {
	
	my ($this) = @_;

	return @{ $this->{parameters} };
	
}


###############################################################################
#
# get_parameter - return an option that corresponds to the right switch
#
###############################################################################

sub get_parameter {
	
	my ($this, $order) = @_;

	$order--;

	#print join("<---array \n", @{ $this->{parameters} });

	my $parameter = @{ $this->{parameters} }[$order];
	
	#print "parameter -- $order === --->$parameter<--\n";
	
	return $parameter;

}


###############################################################################
#
# get_selected_option - return an option that corresponds to the right switch
#
###############################################################################

sub get_selected_option {

	my ($this) = @_;

        my $switch = $this->{switch};

        $switch =~ s/\-//g;

        return $this->{switch};

}


###############################################################################
#
# add_option - add an option to manage on the command line
#
###############################################################################

sub add_option {

	my ($this, $option) = @_;

	# add the switch to this object
	$this->{options}->{$option->get_short_label()} = $option;
        $this->{options}->{$option->get_long_label()}  = $option;

}


###############################################################################
#
# get_switch - return the value of the switch
#
###############################################################################

sub get_switch {

	my ($this) = @_;

        return $this->{switch};

}


###############################################################################
#
# show_help - display the help for all the command options
#
###############################################################################

sub show_help {

	my ($this) = @_;

        foreach my $option (sort keys %{$this->{options}}) {

                # print "option ==== $option \n";
                print "\t\t-$option      \t".$this->{options}->{$option}->get_help()."\n";
        }

}


1;


__END__

=head1 NAME

Goo::CommandLineManager - Manage command line parameters

=head1 SYNOPSIS

use Goo::CommandLineManager;

=head1 DESCRIPTION

Manage command line arguments.

=head1 METHODS

=over

=item new

constructor

=item get_last_parameter

pop off the last parameter on the command line

=item get_parameters

return all the parameters on the command line

=item get_parameter

return the parameter at a given position

=item get_selected_option

return the switch that is specified

=item add_option

add an option to manage on the command line

=item get_switch

return the value of the switch

=item show_help

display the help for all the command options

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO


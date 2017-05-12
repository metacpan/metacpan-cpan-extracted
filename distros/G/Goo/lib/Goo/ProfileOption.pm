#!/usr/bin/perl

package Goo::ProfileOption;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::ProfileOption.pm
# Description:  Store individual options in the profile
#
# Date          Change
# ----------------------------------------------------------------------------
# 11/08/2005    Added method: test
#
##############################################################################

use strict;

use Goo::Object;
use Goo::Prompter;

use base qw(Goo::Object);


##############################################################################
#
# new - instantiate an profile_option
#
##############################################################################

sub new {

    my ($class, $params) = @_;

    my $this = $class->SUPER::new();

    $this->{text} = $params->{text};

    return $this;

}


##############################################################################
#
# get_text - return the text of the option
#
##############################################################################

sub get_text {

    my ($this) = @_;

    return $this->{text} || "Text not set for Option";

}


##############################################################################
#
# do - carry out the action!
#
##############################################################################

sub do {

    my ($this) = @_;

    unless ($this->{action}) {

        # no action
        Goo::Prompter::say("No action specified for this option.");
    }

}


1;



__END__

=head1 NAME

Goo::ProfileOption - Store individual options in the profile

=head1 SYNOPSIS

use Goo::ProfileOption;

=head1 DESCRIPTION

=head1 METHODS

=over

=item new

constructor

=item get_text

return the text of the option

=item do

carry out the action!

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

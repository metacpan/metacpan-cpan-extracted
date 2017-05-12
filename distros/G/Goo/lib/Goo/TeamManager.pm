#!/usr/bin/perl

package Goo::TeamManager;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::TeamManager.pm
# Description:  Model the Team: who? what? why? where? how?
#
# Date          Change
# -----------------------------------------------------------------------------
# 24/10/2005    Version 1
#
###############################################################################

use strict;
use Goo::SimpleEmailer;


###############################################################################
#
# get_programmer_names - return a list of all programmers
#
###############################################################################

sub get_programmer_names {

    return ("Nigel Hamilton", "Dr Sven Baum", "Marcel Holan");

}


###############################################################################
#
# get_programmer_emails - return a list of all programmer emails
#
###############################################################################

sub get_programmer_emails {

    return qw(nige\@thegoo.org sven\@thegoo.org mh\@thegoo.org);

}


###############################################################################
#
# get_all_nick_names - return a list of all staff members
#
###############################################################################

sub get_all_nick_names {

    return qw(nige mh sven);

}


###############################################################################
#
# send_email - send an email to all staff
#
###############################################################################

sub send_email {

    my ($from, $subject, $body) = @_;

    foreach my $staff_member (get_all_nick_names()) {

        Goo::SimpleEmailer::send_email($from, $staff_member . "\@thegoo.org", $subject, $body);

    }

}


1;


__END__

=head1 NAME

Goo::TeamManager - Model the Team: who? what? why? where? how?

=head1 SYNOPSIS

use Goo::TeamManager;

=head1 DESCRIPTION

Model all the members of a team.

=head1 METHODS

=over

=item get_programmer_names

return a list of all programmers

=item get_programmer_emails

return a list of all programmer emails

=item get_all_nick_names

return a list of nick names for all staff members

=item send_email

send an email to all staff

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO


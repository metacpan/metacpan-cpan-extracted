package Goo::Environment;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Environment.pm
# Description:  Provide info about the environment the program is running in
#
# Date          Change
# -----------------------------------------------------------------------------
# 07/06/2004    Auto generated file
# 07/06/2004    needed to know the IP address of the current maching
# 02/02/2005    Detect if we are in a CGI environment
# 06/02/2005    Added test to see if this is a cronjob
# 15/08/2005    Added method: getUser
# 02/12/2005    Removed backticks from getIPAddress
#
###############################################################################

use strict;
use Goo::Object;
use base qw(Goo::Object);


###############################################################################
#
# is_cgi - is this a cgi script?
#
###############################################################################

sub is_cgi {

    return exists($ENV{'GATEWAY_INTERFACE'});

}


###############################################################################
#
# is_cronjob - is this running as a cronjob?
#
###############################################################################

sub is_cronjob {

    return exists($ENV{'TERM'});

}


###############################################################################
#
# is_command_line - is this running on command line?
#
###############################################################################

sub is_command_line {

    return exists($ENV{'TERM'});

}


###############################################################################
#
# get_ipaddress - which machine is this running on?
#
###############################################################################

sub get_ipaddress {

    my ($this) = @_;

    require Socket;
    require Sys::Hostname;

    my $hostname   = Sys::Hostname::hostname();
    my $ip_address = Socket::inet_ntoa(scalar gethostbyname($hostname ||
                                                            'localhost')
                                      );

    return $ip_address;

}


###############################################################################
#
# get_user - who is using this program?
#
###############################################################################

sub get_user {

    return $ENV{'USER'};

}

1;


__END__

=head1 NAME

Goo::Environment - Provide details about the environment The Goo is running in

=head1 SYNOPSIS

use Goo::Environment;

=head1 DESCRIPTION



=head1 METHODS

=over

=item is_cgi

is this a cgi script?

=item is_cronjob

is this running as a cronjob?

=item is_command_line

is this running on command line?

=item get_ipaddress

which machine is this running on?

=item get_user

who is using this program?

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO


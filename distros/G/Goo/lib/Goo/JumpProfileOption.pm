#!/usr/bin/perl

package Goo::JumpProfileOption;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::JumpProfileOption.pm
# Description:  Handle simple Jumps to matching strings for example
#
# Date          Change
# ----------------------------------------------------------------------------
# 11/08/2005    Added method: test
#
##############################################################################

use strict;

use Goo::ProfileOption;

use base qw(Goo::ProfileOption);


##############################################################################
#
# new - construct a profile_option
#
##############################################################################

sub new {

    my ($class, $params) = @_;

    my $this = $class->SUPER::new($params);

    $this->{thing}      = $params->{thing};
    $this->{match_text} = $params->{text};

    return $this;
}


##############################################################################
#
# do - carry out the action!
#
##############################################################################

sub do {

    my ($this) = @_;

    $this->{thing}->do_action("J", $this->{match_text});

}

1;


__END__

=head1 NAME

Goo::JumpProfileOption - Handle simple Jumps to matching strings for example

=head1 SYNOPSIS

use Goo::JumpProfileOption;

=head1 DESCRIPTION


=head1 METHODS

=over

=item new

construct a profile_option

=item do

carry out the action!


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO


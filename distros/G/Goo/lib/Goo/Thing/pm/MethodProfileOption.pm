#!/usr/bin/perl

package Goo::Thing::pm::MethodProfileOption;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::pm::MethodProfileOption.pm
# Description:  Store individual options in the profile
#
# Date          Change
# ----------------------------------------------------------------------------
# 11/08/2005    Added method: test
#
##############################################################################

use strict;

use Goo::TextUtilities;
use Goo::ProfileOption;
use Goo::Thing::pm::MethodMatcher;

use base qw(Goo::ProfileOption);


##############################################################################
#
# new - construct a profile_option
#
##############################################################################

sub new {

    my ($class, $params) = @_;

    my $this = $class->SUPER::new($params);

    $this->{thing}       = $params->{thing};
    $this->{method_name} = $params->{text};

    return $this;
}


##############################################################################
#
# do - carry out the action!
#
##############################################################################

sub do {

    my ($this) = @_;

    my $matching_line_number =
        Goo::Thing::pm::MethodMatcher::get_line_number($this->{method_name},
                                                       $this->{thing}->get_file());
    $this->{thing}->do_action("E", $matching_line_number);

}

1;


__END__

=head1 NAME

Goo::Thing::pm::MethodProfileOption - Store individual options in the profile

=head1 SYNOPSIS

use Goo::Thing::pm::MethodProfileOption;

=head1 DESCRIPTION



=head1 METHODS

=over

=item new

constructor

=item do

carry out the action!


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO


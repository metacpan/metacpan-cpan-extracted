#!/usr/bin/perl

package Goo::ThingProfileOption;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::ThingProfileOption.pm
# Description:  Store individual options in the profile
#
# Date          Change
# ----------------------------------------------------------------------------
# 11/08/2005    Added method: test
#
##############################################################################

use strict;

use Goo::Loader;
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

    $this->{thing} = $params->{thing};

    return $this;
}


##############################################################################
#
# do - carry out the action!
#
##############################################################################

sub do {

    my ($this) = @_;

    # load the thing for this object
    my $new_thing = Goo::Loader::load($this->{text});

    # profile this Thing
    $new_thing->do_action("P");

}


1;



__END__

=head1 NAME

Goo::ThingProfileOption - Store individual options in the profile

=head1 SYNOPSIS

use Goo::ThingProfileOption;

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


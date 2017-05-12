#!/usr/bin/perl

package Goo::TemplateProfileOption;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::TemplateProfileOption.pm
# Description:  Store individual options in the profile
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
# new - construct a ProfileOption
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
# do - carry out the action! - the action should be to jump to the first token
#
##############################################################################

sub do {

    my ($this, $thing) = @_;

    $thing->do_action("J", $this->{text});

}

1;


__END__

=head1 NAME

Goo::TemplateProfileOption - Store individual options in the profile

=head1 SYNOPSIS

use Goo::TemplateProfileOption;

=head1 DESCRIPTION


=head1 METHODS

=over

=item new

construct a ProfileOption

=item do

the action jumps to the first token found inside the Thing

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO


# -*- Mode: cperl; mode: folding; -*-

package Goo::DatabaseProfileOption;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     GooDatabaseProfileOption.pm
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
# new - construct a profile_option
#
##############################################################################

sub new {

    my ($class, $params) = @_;

    my $this = $class->SUPER::new($params);

    $this->{thing}      = $params->{thing};
    $this->{field_name} = $params->{text};

    return $this;
}


##############################################################################
#
# do - carry out the action!
#
##############################################################################

sub do {

    my ($this) = @_;

    $this->{thing}->do_action("E", $this->{field_name});

}

1;



__END__

=head1 NAME

Goo::DatabaseProfileOption - Store individual options in the profile

=head1 SYNOPSIS

use Goo::DatabaseProfileOption;

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


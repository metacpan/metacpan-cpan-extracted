#!/usr/bin/perl

package Goo::Thing::pm::MethodMaker;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::pm::MethodMaker.pm
# Description:  Create a method body
#
# Date          Change
# -----------------------------------------------------------------------------
# 15/02/2005    Auto generated file
# 15/02/2005    Needed to reuse this code and simplify ProgramMaker
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Prompter;

use Goo::Thing::pm::Method;


our @ISA = ("Goo::Object");


###############################################################################
#
# generate_methods - add methods to the progeam
#
###############################################################################

sub generate_methods {

    my ($this, $has_constructor) = @_;

    my @methods;

    while (1) {

        my $method = Goo::Prompter::ask("Add a method?");

        if ($method eq "") { last; }

        my $description = Goo::Prompter::ask("Enter a description for $method?");

        my @parameters =
            Goo::Prompter::keep_asking("enter a parameter for $method (mandatories first)?");

        # prepend a $ sign if it doesn't have one
        @parameters = map { $_ =~ /\$/ ? $_ : '$' . $_ }
            grep { $_ !~ /this/ } @parameters;

        if ($has_constructor) {

            # add this to the parameters - if we have a constructor
            # $this is the first parameter for all OO classes
            unshift(@parameters, '$this');
        }

        my $signature = join(', ', @parameters);

        my $m =
            Goo::Thing::pm::Method->new(
                                        { method      => $method,
                                          signature   => $signature,
                                          description => $description
                                        }
                                       );

        # print "pushing new method on .... ".$m->to_string();
        push(@methods, $m);

    }

    return @methods;

}


1;


__END__

=head1 NAME

Goo::Thing::pm::MethodMaker - Create a method body

=head1 SYNOPSIS

use Goo::Thing::pm::MethodMaker;

=head1 DESCRIPTION



=head1 METHODS

=over

=item generate_methods

add methods to the progeam


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO


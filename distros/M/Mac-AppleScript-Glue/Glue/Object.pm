package Mac::AppleScript::Glue::Object;

=head1 NAME

Mac::AppleScript::Glue::Object - represents an AppleScript object reference


=head1 SYNOPSIS

    use Mac::AppleScript::Glue::Object;

    my $obj = new Mac::AppleScript::Glue::Object(
        ref => 'folder "Applications"',
        app => $my_app,
    );


=head1 DESCRIPTION

Objects of this module store an AppleScript "object reference," which
is a way that AppleScript refers to an object.

See L<Mac::AppleScript::Glue> for full information on how to use this
package.

=cut

use strict;
use warnings;

######################################################################

use Carp;

use Mac::AppleScript::Glue qw(to_string);

use base qw(Mac::AppleScript::Glue);

######################################################################
# methods

=head1 METHODS

=over 4

=cut

######################################################################

=item new

Creates a new Mac::AppleScript::Glue::Object object.

=cut

sub _init {
    my ($self, $args) = @_;

    $self->{_app} = undef;
    $self->{_ref} = undef;

    return $self->SUPER::_init($args);
}

######################################################################

=item app

Contains a Mac::AppleScript::Application object to which to send any
AppleScripts.  If not set, then the script is run without targeting
any application.

=cut

# implemented via $AUTOLOAD

######################################################################

=item ref

The value of the object reference as a string.

=cut

# implemented via $AUTOLOAD

######################################################################

#
# Called by the AUTOLOADer in Mac::AppleScript::Glue when the
# specified method isn't known.
#
# Usage: $obj->_unknown_method('method' [, $arg] 
#                                       [, param1 => val1, param2 => val2]);
#

sub _unknown_method {
    my ($self, $method, @args) = @_;

    my $expr;

    #
    # implicit "get" on any method
    #

##    $expr .= 'get ';

    #
    # we start out with the method, with spaces converted to
    # underscores
    #

    $method =~ s/_/ /g;

    $expr .= $method;

    #
    # if there's only one argument, or there's an odd number (meaning
    # one argument and a hash), then we add on the argument to the
    # expression
    #

    if (@args == 1 || @args % 2 != 0) {
        $expr .= ' ' . to_string(shift @args);
    }

    #
    # we add the reference (this isn't always the right way to do it)
    #
    # an alternate way (which doesn't quite work either) is to
    # enclosed the entire expression in a "tell" block:
    #
    # $expr = 'tell ' . $self->ref . "\n" 
    #     . "$expr\n" 
    #     . "end tell";
    #

;;if ($self->ref !~ /^application "/) {
    $expr .= ' of (' . $self->ref . ')';
;;}

    #
    # if there are parameters, we add each parameter
    #

    if (@args) {
        my %args = @args;

        while (my ($name, $value) = each %args) {
            $name =~ s/_/ /g;

            $expr .= " $name " . to_string($value);
        }
    }

    #
    # finally, we run the expression, either using the application
    # specified in the object, or the object itself
    #

    my $app = $self->app || $self;

    return $app->run($expr);
}

######################################################################

=item set(arg1 => val1, arg2 => val2, ...)

Sets the value of one or more properties in the object reference.
Returns the result, if any, of the last "set" property.

=cut

sub set {
    my ($self, %args) = @_;

    my $app = $self->app || $self;

    my $r;

    while (my ($method, $value) = each %args) {
        $method =~ s/_/ /g;

        $r = $app->run(
            "set $method of (" 
            . $self->ref 
            . ') to ' 
            . to_string($value)
        );
    }

    return $r;
}

######################################################################

=back

=head1 SEE ALSO

L<Mac::AppleScript::Glue>

L<Mac::AppleScript::Glue::Application>


=head1 AUTHOR

John Labovitz E<lt>johnl@johnlabovitz.comE<gt>


=head1 COPYRIGHT

Copyright (c) 2002 John Labovitz. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself. 

=cut

1;

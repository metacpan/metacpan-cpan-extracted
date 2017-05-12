package Mac::AppleScript::Glue::Application;

=head1 NAME

Mac::AppleScript::Glue::Application - an application to send AppleScript to


=head1 SYNOPSIS

    use Mac::AppleScript::Glue;
    use Mac::AppleScript::Glue::Application;

    my $finder = new Mac::AppleScript::Glue::Application('Finder');

    my $version = $finder->version;


=head1 DESCRIPTION

Objects of this module are used to send events to an application.

See L<Mac::AppleScript::Glue> for full information on how to use this
package.


=cut

######################################################################

use strict;
use warnings;

use base qw(Mac::AppleScript::Glue::Object);

######################################################################
######################################################################
# methods

=head1 METHODS

=over 4

=cut

######################################################################

=item new($app_name [, $machine ])

Creates a new application object for the C<$app_name> application.  

If C<$machine> is specified, the specified computer will be sent
events instead of the local machine.  This uses Apple Remote Events,
which you'll have to have enabled on the remote machine before events
can be sent to it.  (Look in the B<Sharing> system preference or 
control panel on the remote machine.)

NOTE: Documentation on remote events is a little vague; it seems that
you specify the remote machine as a URL like C<< eppc://<host> >>,
where C<< <host> >> is either a hostname or IP address.  "EPPC" stands
for Event Program to Program Communication, apparently.

=cut

# implemented via $AUTOLOAD

######################################################################

sub _init {
    my ($self, $args) = @_;

    $self->{_app_name} = shift @$args;
    $self->{_machine} = shift @$args;

    return $self->SUPER::_init($args);
}

######################################################################

=item app_name

Returns the name of the application connected to this object.

=cut

# implemented via $AUTOLOAD

######################################################################

=item ref

Returns the AppleScript object reference for this application.

=cut

sub ref {
    my ($self) = @_;

    my $ref = 'application "' . $self->app_name . '"';

    if ($self->machine) {
        $ref .= ' of machine "' . $self->machine . '"';
    }

    return $ref;
}

######################################################################

=item run(@script)

Sends a user-specified AppleScript to this application.  The script
can be a simple one-liner or a multi-line script; in either case,
script lines should not contain newlines.  If the script returns a
value, it will be parsed into Perl data structures.

=cut

sub run {
    my ($self, @script) = @_;

    return $self->SUPER::run(
        "tell " . $self->ref,
        @script,
        "end tell",
    );
}

######################################################################

=item objref($ref)

=item objref($class => $string)

Creates an object reference to use as a standalone object.  If you
have a complete object reference (like C<application "Finder">), you
can pass that as a single argument:

    $app->objref('application "Finder"');

You can also have C<objref()> make up the object reference for you out
of a class and string:

    $app->objref(application => 'Finder');

This is simply a shortcut to calling Mac::AppleScript::Glue::Object's
C<new> method.

=cut

sub objref {
    my $self = shift;

    my $ref;

    if (@_ > 1) {
        my ($class, $string) = (shift, shift);
        $class =~ s/_/ /g;
        $ref = "$class \"$string\"";

    } else {
        $ref = shift;
    }

    return new Mac::AppleScript::Glue::Object(
        ref => $ref,
        app => $self,
    );
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

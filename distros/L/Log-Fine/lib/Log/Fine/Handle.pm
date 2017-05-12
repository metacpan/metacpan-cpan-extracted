
=head1 NAME

Log::Fine::Handle - Controls where to send logging output

=head1 SYNOPSIS

Sets up an output handle for log messages

    use Log::Fine;
    use Log::Fine::Handle;

    # Instantiate the handle (default values shown)
    my $handle = Log::Fine::Handle::Foo
        ->new( name      => "foo0",
               mask      => Log::Fine::Handle->DEFAULT_LOGMASK,
               formatter => Log::Fine::Formatter:Basic->new() );

    # See if a handle is loggable at a given level
    my $rc = $handle->isLoggable(INFO);

    # Write a message
    $handle->msgWrite(INFO, "Informational message", 1);

=head1 DESCRIPTION

A Log::Fine::Handle object controls I<where> to send formatted log
messages.  The destination can be a file, syslog, a database table, or
simply to output.  Message formatting is then handled by a
L<formatter|Log::Fine::Formatter> object.

=cut

use strict;
use warnings;

package Log::Fine::Handle;

use base qw( Log::Fine );

use Log::Fine;
use Log::Fine::Formatter::Basic;
use Log::Fine::Levels;

our $VERSION = $Log::Fine::VERSION;

=head1 METHODS

=head2 bitmaskListEnabled

Gets a list of enabled bit masks

=head3 Returns

An array containing a list of strings representing bitmasks
enabled for this handle

=cut

sub bitmaskListEnabled
{

        my $self     = shift;
        my $map      = $self->levelMap();
        my @bitmasks = ();

        # Reminder: log() here is the perl logarithmic function (see
        # perlfunc(3)) and is not to be confused with the name of this
        # module ;)
        foreach my $maskname ($map->logMasks()) {
                push @bitmasks, $maskname
                    if $self->isLoggable(log($map->maskToValue($maskname)) / log(2) - 1);
        }

        return @bitmasks;

}          # bitmaskListEnabled()

=head2 formatter

Getter/Setter for the objects formatter attribute

=head3 Parameters

=over

=item  * formatter

B<[optional]> A valid L<Log::Fine::Formatter> object

=back

=head3 Returns

A L<Log::Fine::Formatter> object

=cut

sub formatter
{

        my $self      = shift;
        my $formatter = shift;

        # Should the first argument is a valid formatter, then set the
        # objects formatter attribute appropriately
        $self->{formatter} = $formatter
            if (    defined $formatter
                and ref $formatter
                and UNIVERSAL::can($formatter, 'isa')
                and $formatter->isa("Log::Fine::Formatter"));

        # return the objects formatter attribute
        return $self->{formatter};

}          # formatter()

=head2 isLoggable

Specifies whether the handle is loggable at the given level.

=head3 Parameters

=over

=item  * level

Name of level or numeric value representing level

=back

=head3 Returns

1 if this level is loggable, undef otherwise

=cut

sub isLoggable
{

        my $self = shift;
        my $lvl  = shift;

        # Return undef if level is not defined
        return unless defined $lvl;

        # Convert level to value if we are given a string, otherwise
        # use value as is.
        my $val =
            ($lvl =~ /^\d+$/) ? $lvl : $self->levelMap()->levelToValue($lvl);

        # Make sure we have a valid value
        return unless defined($val);

        my $shifted = 2 << $val;

        # Bitand the level and the mask to see if we're loggable
        return (($self->{mask} & $shifted) == $shifted) ? 1 : undef;

}          # isLoggable()

=head2 msgWrite

Tells the handle to output the given log message.

B<Note:> msgWrite() is an I<internal> method to the Log::Fine
framework, meant to be sub-classed.  Use
L<Log::Fine::Logger/log> for actual logging.

=head3 Parameters

=over

=item  * level

Level at which to log

=item  * message

Message to log

=item  * skip

Passed to L<caller|perlfunc/caller> for accurate method logging

=back

=head3 Returns

None

=cut

sub msgWrite
{

        my $self  = shift;
        my $class = ref $self;

        my $msg =
            ($class eq 'Log::Fine::Handle')
            ? "direct call to abstract method msgWrite()!\n  See Log::Fine::Handle documentation"
            : "call to abstract method ${class}::msgWrite()";

        $self->_fatal($msg);

}          # msgWrite()

# --------------------------------------------------------------------

##
# Initializes our object

sub _init
{

        my $self = shift;

        # Perform any necessary upper class initializations
        $self->SUPER::_init();

        # Set default bitmask
        $self->{mask} = $self->levelMap()->bitmaskAll()
            unless defined $self->{mask};

        # Set the default formatter
        $self->{formatter} = Log::Fine::Formatter::Basic->new()
            unless (    defined $self->{formatter}
                    and ref $self->{formatter}
                    and UNIVERSAL::can($self->{formatter}, 'isa')
                    and $self->{formatter}->isa("Log::Fine::Formatter"));

        return $self;

}          # _init()

=head1 BUGS

Please report any bugs or feature requests to
C<bug-log-fine-handle at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Fine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Fine

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Fine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Fine>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Fine>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Fine>

=back

=head1 AUTHOR

Christopher M. Fuhrman, C<< <cfuhrman at pobox.com> >>

=head1 SEE ALSO

L<perl>, L<Log::Fine>, L<Log::Fine::Formatter>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008, 2010-2011, 2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Handle

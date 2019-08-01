package MPV::Simple;

use strict;
use warnings;
use Carp;


require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MPV::Simple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.63';

require XSLoader;
XSLoader::load('MPV::Simple', $VERSION);

our $callback = undef();
our $callback_data = undef();

our @event_names = qw(
    none
    shutdown
    log-message
    get-property-reply
    set-property-reply
    command-reply
    start-file
    end-file
    file-loaded
    tracks-changed
    tracks-switched
    idle
    pause
    unpause
    tick
    script-input-dispatch
    client-message
    video-reconfig
    audio-reconfig
    metadata-update
    seek
    playback-restart
    property-change
    chapter-change
    queue-overflow
    hook
    );

sub check_error {
    my ($status) = @_;
    return unless ($status);
    #print "STATUS $status\n";
    if ($status < 0) {
        my $error_string = MPV::Simple::error_string( $status );
        croak "mpv API error: $error_string\n";
    }
}

sub warn_error {
    my ($status) = @_;
    return unless ($status);
    #print "STATUS $status\n";
    if ($status < 0) {
        my $error_string = MPV::Simple::error_string( $status );
        carp "mpv API error: $error_string\n";
    }
}


# Preloaded methods go here.

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MPV::Simple - Perl extension for the MPV audio and video player using libmpv

=head1 SYNOPSIS

    use MPV::Simple;
    my $ctx = MPV::Simple->new();
    $ctx->initialize;
    $ctx->set_property_string('input-default-bindings','yes');
    $ctx->set_property_string('input-vo-keyboard','yes');
    $ctx->set_property_string('osc','yes');

    $ctx->command("loadfile", "/home/maximilian/Dokumente/perl/MPV-Simple/t/einladung2.mp4");
    while (my $event = $ctx->wait_event(-1)) {
            if ($event->{id} == 7){
                    $ctx->terminate_destroy();
                    last;
            }
    }

    exit 0;

=head1 DESCRIPTION

MPV::Simple is a basic and simple binding to libmpv/MPV.

=head2 WARNING

The module is in the ALPHA stadium (as well as the libmpv API). API could be changed in the future.

=head2 METHODS

The following methods exist:

=over 4

=item * my $mpv = MPV::Simple->new()
Constructs a new MPV handle

=item * $mpv->initialize();
Initialize an uninitialized mpv instance. If the mpv instance is already running, an error is retuned. This function needs to be called to make full use of the client API if the client API handle was created with new().

=item * $mpv->set_property_string('name','value');
Set a property to a given value. Properties are essentially variables which can be queried or set at runtime. For example, writing to the pause property will actually pause or unpause playback. For true you have to write "yes", for false "no"

=item * $mpv->get_property_string('name','value');
Return the value of the property with the given name as string.

=item * $mpv->observe_property_string('name', reply_userdata);
Get a notification whenever the given property changes. You will receive updates as mpv event MPV_EVENT_PROPERTY_CHANGE. Note that this is not very precise: for some properties, it may not send updates even if the property changed. This depends on the property, and it's a valid feature request to ask for better update handling of a specific property. (For some properties, like ``clock``, which shows the wall clock, this mechanism doesn't make too much sense anyway.)
Observing a property that doesn't exist is allowed. (Although it may still cause some sporadic change events.)
Keep in mind that you will get change notifications even if you change a property yourself. Try to avoid endless feedback loops, which could happen if you react to the change notifications triggered by your own change.
The parameter reply_userdata will be used for the mpv_event.reply_userdata field for the received MPV_EVENT_PROPERTY_CHANGE events. If you have no use for this, pass 0. Also see mpv_unobserve_property().

=item * $mpv->unobserve_property(registered_reply_userdata);
Undo mpv_observe_property(). This will remove all observed properties for which the given number was passed as reply_userdata to mpv_observe_property.

=item * $mpv->command($command, @args);
Send a command to the player. Commands are the same as those used in L<input.conf>, except that this function takes parameters in a pre-split form. The commands and their parameters are documented in input.rst.

=item * $mpv->wait_event($timeout)
Wait for the next event, or until the timeout expires, or if another thread makes a call to mpv_wakeup(). Passing 0 as timeout will never wait, and is suitable for polling.
The internal event queue has a limited size (per client handle). If you don't empty the event queue quickly enough with mpv_wait_event(), it will overflow and silently discard further events. If this happens, making asynchronous requests will fail as well (with MPV_ERROR_EVENT_QUEUE_FULL).

=item * $mpv->terminate_destroy()
Brings the player and all clients down as well, and waits until all of them are destroyed. Returns a hashref containing the event ID and other data.
 
=back


=head2 Integrating in foreign event loop (especially interaction with GUI's)

In general, the API user should run an event loop in order to receive events. This event loop should call mpv_wait_event(), which will return once a new mpv client API is available. It is also possible to integrate client API usage in other event loops (e.g. GUI toolkits). In the C-API this can be done with the mpv_set_wakeup_callback() function, and then polling for events by calling mpv_wait_event() with a 0 timeout. Unfortunately the callback function is called from a arbitrary thread so that Perl doesn't support this way (or does it? Then please help to integrate this feature). Instead you should use MPV::Simple::Pipe in this case. This let MPV run in a seperate process. MPV communicates there with the GUI part through pipes. The MPV process mainly starts an event loop in which it calls mpv_wait_event with a timeout of 0 and looks for new commands (very similar to the original C mpv_set_wakeup_callback way).

=head2 Error handling

In MPV 0 and positive return values always mean success, negative values are always errors. So you cannot use C<or die "...:$!\n" with MPV methods. You can use C<MPV::Simple::error_string($status)> on the returned value to get the error reason. Furthermore you can die on an error with C<MPV::Simple::check_error($mpv->command(...)> or print a warning with C<MPV::Simple::warn_error($mpv->command(...)>.

=head1 SEE ALSO

See the doxygen documentation at L<https://github.com/mpv-player/mpv/blob/master/libmpv/client.h> and the manual of the mpv media player in L<http://mpv.io>.

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License for more details.

=cut

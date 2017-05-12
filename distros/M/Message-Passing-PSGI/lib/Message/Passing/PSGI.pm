package Message::Passing::PSGI;
use strict;
use warnings;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

1;

=head1 NAME

Message::Passing::PSGI - ALPHA QUALITY PSGI adaptor for Message::Passing

=head1 SYNOPSIS

    # Run the server - note that the -e has to all be on one line!
    plackup -E production -s Twiggy -MPlack::App::Message::Passing -e'Plack::App::Message::Passing->new(return_address => "tcp://127.0.0.1:5555", send_address => "tcp://127.0.0.1:5556")->to_app'

    # Run your app with the handler
    plackup -E production -s Message::Passing testapp.psgi --host 127.0.0.1 --port 5556

    # Browse to:
    http://localhost:5000/

=head1 DESCRIPTION

B<ALPHA QUALITY EXPERIMENT - YOU HAVE BEEN WARNED!>

This module implements a mongrel2 like strategy for web handlers, using
L<Message::Passing::ZeroMQ>.

=head1 WHY

Because I could! It's a useful experiment to prove that L<Message::Passing>
can be used for things entirely unlike my initial goals.

=head2 NO, REALLY?

B<Theoretically>, this is quite an interesting model - as you've totally split
the front end connection acceptance and the back end request handling,
you can do things which are harder in other server environments trivially.

Examples of things that 'just work' include:

=over

=item Adding more handler processes

Totally dynamic, run as many as you want

=item Adding handler processes on other servers

As long as your send/return sockets are bound to a host that's network
accessible, you can spin up handlers wherever you want.

=item Upgrade the application in production

You can spin up a new version, verify it appears to be working correctly
etc before shutting down the old version

=item Profile the application in production

Just run a handler with NYTProf..

=back

B<NOTE:> The properties above _do not_ exist in the current code - you
B<will> drop requests in-flight if you shut handlers down!! (Patches to fix
this should not be that hard, and would be welcome if anyone is interested)

If you're actually interested in using this in production, I'd recommend
you look at the real mongrel2, and L<Plack::Handler::Mongrel2>.

=head1 BUGS

Many, and varied. Please do not try to run this in production ;_)

Issues include:

=over

=item Large responses will use SEVERAL times the response length in RAM

=item Requests never timeout

=item App Handler crashes / restarts will lost in-flight requests.

=item Quite probably leaks RAM.

This has not been tested, which means I quite probably got it wrong somewhere ;)

=back

=head1 SEE ALSO

=over

=item L<Plack::App::Message::Passing>.

=item L<Plack::Handler::Message::Passing>.

=item mongrel2

=item L<Message::Passing>

=item L<Message::Passing::ZeroMQ>.

=back

=head1 AUTHOR

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

=head1 COPYRIGHT

Copyright the above author.

=head1 LICENSE

GNU Affero General Public License, Version 3

If you feel this is too restrictive to be able to use this software,
please talk to us as we'd be willing to consider re-licensing under
less restrictive terms.

=cut

1;


package Eve::Event::HttpRequestReceived;

use parent qw(Eve::Event);

use strict;
use warnings;

=head1 NAME

B<Eve::Event::HttpRequestReceived> - HTTP request received.

=head1 SYNOPSIS

    use Eve::Event::HttpRequestReceived;

    Eve::Event::HttpRequestReceived->new(
        event_map => $event_map);

=head1 DESCRIPTION

B<Eve::Event::HttpRequestReceived> is an event assumed to signal
about a new HTTP request. It is assumed to be the first event in any
web application.

=head3 Constructor arguments

=over 4

=item C<event_map>

an event map object

=back

=head1 SEE ALSO

=over 4

=item L<Eve::Event>

=item L<Eve::EventMap>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=back

=cut

1;

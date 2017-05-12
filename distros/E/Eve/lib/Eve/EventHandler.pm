package Eve::EventHandler;

use parent qw(Eve::Class);

use strict;
use warnings;

=head1 NAME

Eve::EventHandler - a base class for event handlers.

=head1 SYNOPSIS

    use parent qw(Eve::EventHandler);

=head1 DESCRIPTION

B<Eve::EventHandler> is an abstraction for all the event handles
classes.

=head1 METHODS

=head2 B<handle()>

The C<handle> method must be overriden. It is called when an
appropriate event is triggered.

=head3 Arguments

=over 3

=item C<event>

an event that has been triggered.

=back

=cut

sub handle {
    Eve::Error::NotImplemented->throw();
}

=head1 SEE ALSO

=over 4

=item L<Eve::Class>

=item L<Eve::Event>

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

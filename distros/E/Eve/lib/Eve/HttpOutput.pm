package Eve::HttpOutput;

use parent qw(Eve::Class);

use strict;
use warnings;

=head1 NAME

B<Eve::HttpOutput> - an event handler for HTTP response events.

=head1 SYNOPSIS

    use Eve::HttpOuput;

    my $output = Eve::HttpOutput->new(filehandle => STDOUT);
    $dispatcher->handle(event => $event);

=head1 DESCRIPTION

B<Eve::HttpOutput> class is an output controller for HTTP
applications.

=head3 Constructor arguments

=over 3

=item C<filehandle>

a filehandle to write the output data to. Usualy it is STDOUT,

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash, my $filehandle);

    $self->{'_filehandle'} = $filehandle;

    return;
}

=head2 B<handle()>

Handles an event containing an HTTP response instance performing the
output.

=head3 Arguments

=over 4

=item C<event>

an event containing the HTTP response object.

=back

=cut

sub handle {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $event);

    print {$self->_filehandle} $event->response->get_text();

    return;
}

=head1 SEE ALSO

=over 4

=item L<Eve::Class>

=item L<Eve::HttpResponse>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;

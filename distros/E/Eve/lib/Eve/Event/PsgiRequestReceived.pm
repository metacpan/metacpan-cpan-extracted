package Eve::Event::PsgiRequestReceived;

use parent qw(Eve::Event::HttpRequestReceived);

use strict;
use warnings;

=head1 NAME

B<Eve::Event::PsgiRequestReceived> - HTTP request received through PSGI.

=head1 SYNOPSIS

    use Eve::Event::PsgiRequestReceived;

    Eve::Event::PsgiRequestReceived->new(
        event_map => $event_map,
        env_hash => $env);

=head1 DESCRIPTION

B<Eve::Event::PsgiRequestReceived> is an event assumed to signal
about a new HTTP request that was dispatched by a PSGI handler. It
differs from a plain HTTP request event in a way that it must contain
the environment hash that was passed by the handler.

=head3 Properties

=over 4

=item C<env_hash>

=back

=head3 Constructor arguments

=over 4

=item C<event_map>

an event map object

=item C<env_hash>

an environment hash passed by the PSGI handler.

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    my $arguments = Eve::Support::arguments(\%arg_hash, my $env_hash);

    $self->SUPER::init(%{$arguments});

    $self->{'env_hash'} = $env_hash;
    $self->{'response'} = undef;
}

=head1 SEE ALSO

=over 4

=item L<Eve::Event::HttpRequestReceived>

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

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;

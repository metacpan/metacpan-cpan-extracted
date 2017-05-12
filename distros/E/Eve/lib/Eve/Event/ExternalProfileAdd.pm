package Eve::Event::ExternalProfileAdd;

use parent qw(Eve::Event);

use strict;
use warnings;

=head1 NAME

B<Eve::Event::ExternalProfileAdd> - a new external profile is added.

=head1 SYNOPSIS

    use Eve::Event::ExternalProfileAdd;

    Eve::Event::ExternalProfileAdd->new(
        external_profile => $external_profile,
        event_map => $event_map);

=head1 DESCRIPTION

B<Eve::Event::ExternalProfileAdd> is an event assumed to signal
about a previously unknown external signup profile added to the
database.

=head3 Attributes

=over 4

=item C<external_profile_entry>

an external profile object (C<Eve::Item::ExternalProfileEntry>)

=back

=head3 Constructor arguments

=over 4

=item C<external_profile_entry>

an external profile object (C<Eve::Item::ExternalProfileEntry>)

=item C<event_map>

an event map object (C<Eve::EventMap>).

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    my $arg_hash = Eve::Support::arguments(
        \%arg_hash, my ($external_profile_entry));

    $self->SUPER::init(%{$arg_hash});

    $self->{'external_profile_entry'} = $external_profile_entry;
}

=head1 SEE ALSO

=over 4

=item L<Eve::Event>

=item L<Eve::EventMap>

=item L<Eve::Item:ExternalProfile>

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

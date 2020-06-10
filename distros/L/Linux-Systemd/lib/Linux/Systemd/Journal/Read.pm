package Linux::Systemd::Journal::Read 1.201600;

# ABSTRACT: Read from systemd journals

# TODO make sure all text is utf8

use v5.10.2;
use Moo;
use Carp;
use XSLoader;
XSLoader::load;

sub BUILD {
    return __open();
}


sub get_next_entry {
    my $self = shift;

    if ($self->next > 0) {
        return $self->get_entry;
    }
    return;
}

# TODO
# sd_journal_add_match(), sd_journal_add_disjunction() and sd_journal_add_conjunction(
# wrap these so we can specify a either a search string, like:
# match(PRIORITY=5 NOT SYSLOG_IDENTIFIER=KERNEL)
# or maybe something like...
# match(priority => 5, syslog_identifier => 'KERNEL')->not(something => idontwant)

sub _match {
    my $self = shift;

    # matches will be an array of [key, value] arrayrefs
    my @matches;

    if (scalar @_ == 1 && ref $_[0]) {

        my $ref = ref $_[0];
        if ($ref eq 'ARRAY') {

            # already an arrayref
            push @matches, $_[0];
        } elsif ($ref eq 'HASH') {

            # hashref, convert to array
            my @array = map { $_ => $_[0]->{$_} } keys %{$_[0]};
            push @matches, \@array;
        }
    } elsif (scalar @_ % 2 == 0) {
        say "even sized list";
        while (@_) {
            push @matches, [shift, shift];
        }
    }

    croak 'Invalid params' unless @matches;

    # $key = uc $key;
    foreach my $pair (@matches) {
        __add_match(uc($pair->[0]) . "=" . $pair->[1]);
    }
}


sub match {
    my $self = shift;
    return $self->_match(@_);
}


sub match_and {
    my $self = shift;
    __match_and();
    return $self->_match(@_);
}


sub match_or {
    my $self = shift;
    __match_or();
    return $self->_match(@_);
}


1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers

=head1 NAME

Linux::Systemd::Journal::Read - Read from systemd journals

=head1 VERSION

version 1.201600

=head1 METHODS

=head2 c<get_usage>

Returns the number of bytes used by the open journal

=head2 C<seek_head>

Seeks to the start of the open journal.

=head2 C<seek_tail>

Seeks to the end of the open journal.

=head2 C<next>

Moves to the next record.

=head2 C<get_data($field)>

Returns the value of C<$field> from the current record.

See L<systemd.journal-fields(7)> for a list of well-known fields.

=head2 C<get_entry>

Returns a hashref of all the fields in the current entry.

This method is not a direct wrap of the journal API.

=head2 C<get_next_entry>

Convenience wrapper which calls L</next> before L</get_entry>

This method is not a direct wrap of the journal API.

=head2 C<match(field => value)>

=head2 C<match_and(field => value)>

=head2 C<match_or(field => value)>

=head2 C<flush_matches>

Clears the match filters.

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Ioan Rogers.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

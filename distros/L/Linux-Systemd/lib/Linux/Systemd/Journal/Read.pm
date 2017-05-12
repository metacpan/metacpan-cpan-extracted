package Linux::Systemd::Journal::Read;
$Linux::Systemd::Journal::Read::VERSION = '1.162700';
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

version 1.162700

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

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/Linux-Systemd/issues>.

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Linux-Systemd-Journal/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Linux::Systemd/>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/Linux-Systemd>
and may be cloned from L<git://github.com/ioanrogers/Linux-Systemd.git>

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Ioan Rogers.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

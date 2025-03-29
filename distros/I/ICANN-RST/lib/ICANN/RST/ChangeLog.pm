package ICANN::RST::ChangeLog;
# ABSTRACT: an object representing a set of changes.
use Carp;
use DateTime;
use base qw(ICANN::RST::Base);
use strict;

sub new {
    my ($package, $id, $ref, $spec) = @_;

    croak(sprintf("invalid date format '%s', must be YYYY-MM-DD", $id)) unless ($id =~ /^\d{4}-\d{2}-\d{2}$/);

    #
    # the ICANN::RST::Base constructor expects $ref to be a hashref so we need
    # to wrap it
    #
    return $package->SUPER::new(
        $id,
        {'changes' => $ref},
        $spec,
    );
}

sub date {
    my $self = shift;

    return DateTime->new(
        'year'  => int(substr($self->id, 0, 4)),
        'month' => int(substr($self->id, 5, 2)),
        'day'   => int(substr($self->id, 8, 2)),
    );
}

sub changes { map { ICANN::RST::Text->new($_) } @{$_[0]->{'changes'}} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ICANN::RST::ChangeLog - an object representing a set of changes.

=head1 VERSION

version 0.03

=head1 NAME

This class inherits from L<ICANN::RST::Base> (so it has the C<id()> and
C<spec()> methods).

=head1 METHODS

=head2 date()

Returns a L<DateTime> representing the date of the changes.

=head2 changes()

Returns an array of L<ICANN::RST::Text> objects.

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

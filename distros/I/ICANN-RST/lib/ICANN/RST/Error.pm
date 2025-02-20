package ICANN::RST::Error;
# ABSTRACT: an object representing an RST error.
use base qw(ICANN::RST::Base);
use strict;

sub severity { $_[0]->{'Severity'} }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }

sub cases {
    my $self = shift;

    my %cases;

    foreach my $case ($self->spec->cases) {
        foreach my $error ($case->errors) {
            $cases{$case->id} = $case if ($error->id eq $self->id && !defined($cases{$case->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%cases);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ICANN::RST::Error - an object representing an RST error.

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This class inherits from L<ICANN::RST::Base> (so it has the C<id()> and
C<spec()> methods).

=head1 METHODS

=head2 description()

A L<ICANN::RST::Text> object containing the long textual description of the
error.

=head2 severity()

A string containing one of C<WARNING>, C<ERROR> or C<CRITICAL>.

=head2 cases()

A list of all C<ICANN::RST::Case> objects that produce this error.

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

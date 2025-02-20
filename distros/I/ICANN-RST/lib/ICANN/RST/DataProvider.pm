package ICANN::RST::DataProvider;
# ABSTRACT: an object representing an RST data provider.
use ICANN::RST::DataProvider::Column;
use base qw(ICANN::RST::Base);
use strict;

sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }

sub rows { $_[0]->{'Rows'} }

sub columns { map { ICANN::RST::DataProvider::Column->new($_) } @{$_[0]->{'Columns'}} }

sub cases {
    my $self = shift;

    my %cases;

    foreach my $case ($self->spec->cases) {
        foreach my $provider ($case->providers) {
            $cases{$case->id} = $case if ($provider->id eq $self->id && !defined($cases{$case->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%cases);
}

sub errors {
    my $self = shift;

    my $i = 0;

    my @errors;

    foreach my $column ($self->columns) {
        if ('errorCode' eq $column->name) {
            foreach my $row (@{$self->rows}) {
                push(@errors, $self->spec->error($row->[$i]));
            }

            last;
        }

        $i++;
    }

    return @errors;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ICANN::RST::DataProvider - an object representing an RST data provider.

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This class inherits from L<ICANN::RST::Base> (so it has the C<id()> and
C<spec()> methods).

=head1 METHODS

=head2 description()

A L<ICANN::RST::Text> object containing the long textual description of the
error.

=head2 columns()

An array of L<ICANN::RST::DataProvider::Column> objects representing the columns
for this data provider.

=head2 rows()

An arrayref of arrayrefs containing the rows for this data provider.

=head2 cases()

A list of all C<ICANN::RST::Case> objects that use this data provider.

=head2 errors()

A list of all C<ICANN::RST::Error> objects referenced by this data provider.

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

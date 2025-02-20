package ICANN::RST::DataProvider::Column;
# ABSTRACT: an object representing a column in an RST data provider.
use strict;

sub new {
    my ($package, $ref) = @_;
    return bless($ref, $package);
}

sub name        { $_[0]->{'Name'} }
sub type        { $_[0]->{'Type'} }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ICANN::RST::DataProvider::Column - an object representing a column in an RST data provider.

=head1 VERSION

version 0.01

=head1 METHODS

=head2 name()

The column name.

=head2 type()

The column type.

=head2 description()

A L<ICANN::RST::Text> object containing the textual description of the column.

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package ICANN::RST::Base;
# ABSTRACT: base class for other things.
use Carp;
use YAML::XS;
use strict;

sub new {
    my ($package, $id, $ref, $spec) = @_;

    carp("No reference for '$id'") unless (defined($ref));

    return bless(
        {
            %{$ref},
            'id'    => $id,
            'spec'  => $spec,
        },
        $package,
    );
}

sub id      { $_[0]->{'id'} }
sub order   { int($_[0]->{'Order'}) }
sub spec    { $_[0]->{'spec'} }

sub dump {
    my $self = shift;
    my %hash = %{$self};
    delete($hash{'spec'});
    return YAML::XS::Dump(\%hash);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ICANN::RST::Base - base class for other things.

=head1 VERSION

version 0.01

=head1 METHODS

=head2 id()

Returns a string containing the unique ID of the thing.

=head2 order()

Returns an integer representing the position of the thing among its siblings.

=head2 spec()

Returns a reference to the enclosing L<ICANN::RST::Spec> object.

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

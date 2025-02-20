package ICANN::RST::Resource;
# ABSTRACT: an object representing an RST resource.
use URI;
use base qw(ICANN::RST::Base);
use strict;

sub url { URI->new($_[0]->{'URL'}) }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ICANN::RST::Resource - an object representing an RST resource.

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This class inherits from L<ICANN::RST::Base> (so it has the C<id()> and
C<spec()> methods).

=head1 METHODS

=head2 description()

A L<ICANN::RST::Text> object containing the long textual description of the
resource.

=head2 url()

A L<URI> object representing the URL for this resource.

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

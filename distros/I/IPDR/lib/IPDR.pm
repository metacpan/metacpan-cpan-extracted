package IPDR;

=head1 NAME

IPDR - IPDR Data Suite

=head1 VERSION

Version 0.40

=cut

our $VERSION = '0.40';

=head1 SYNOPSIS

This is a IPDR collection suite for currently Cisco and generic IPDR compliant
servers.

To use the Cisco implementation of IPDR (SAMIS) see the man page

IPDR::Collection::Cisco

To use the Cisco Secure implementation of IPDR (SAMIS) see the man page

IPDR::Collection::CiscoSSL

To use the generic client implementation of IPDR see the man page

IPDR::Collection::Client

The generic client has been tested with Motorola and Arris (although very limited
testing with Arris).

=cut

=head1 AUTHOR

Andrew S. Kennedy, C<< <shamrock at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ipdr-cisco at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPDR>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPDR

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPDR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPDR>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPDR>

=item * Search CPAN

L<http://search.cpan.org/dist/IPDR>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2011 Andrew S. Kennedy, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of IPDR


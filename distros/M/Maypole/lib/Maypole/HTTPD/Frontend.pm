package Maypole::HTTPD::Frontend;
use strict;
use warnings;

use CGI::Maypole 2.11; # 2.11 has collect_output()

use base 'CGI::Maypole';

sub get_request { shift->cgi(CGI->new) }

{ 
    my $output;
    sub send_output { $output = shift->collect_output }
    sub output_now  { print $output; undef $output }
}

1;

=head1 NAME

Maypole::HTTPD::Frontend - Maypole driver class for Maypole::HTTPD

=head1 DESCRIPTION

This is a simple CGI based Maypole driver for L<Maypole::HTTPD>. It's used 
automatically as the frontend by L<Maypole::Application>.

It overrides the following functions in L<CGI::Maypole>:

=over 4

=item get_request

Instantiates a L<CGI> object representing the request.

=item send_output

Stores generated output in a buffer.

=back

=head2 output_now

Actually output what's been buffered by send_output. Used by L<Maypole::HTTPD>

=head1 SEE ALSO

L<Maypole>, L<Maypole::HTTPD>

=cut

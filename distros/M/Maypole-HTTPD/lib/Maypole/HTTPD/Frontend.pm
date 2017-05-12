package Maypole::HTTPD::Frontend;
use base 'CGI::Maypole';
our $ct;
our $output;
our $cgi;

sub get_request { shift->{cgi} = new CGI; }
sub send_output {
    my $r = shift;
    my %headers = (
        -type            => $r->{content_type},
        -charset         => $r->{document_encoding},
        -content_length  => do { use bytes; length $r->{output} },
    );
    foreach ($r->headers_out->field_names) {
        next if /^Content-(Type|Length)/;
        $headers{"-$_"} = $r->headers_out->get($_);
    }

    $output=$r->{cgi}->header(%headers) . $r->{output};
}

sub output_now {
    print $output;
}

1;

=head1 NAME

Maypole::HTTP::Frontend - Maypole driver class for Maypole::HTTPD

=head1 DESCRIPTION

This is a simple CGI based maypole driver for L<Maypole::HTTPD>. It's used 
automatically by the Maypole::HTTPD 'steal' function.

It overrides the following functions in L<CGI::Maypole>:

=over 4

=item get_request

=item send_output

=back

=head2 output_now

Actually output what's been buffered by send_output. Used by L<Maypole::HTTPD>

=head1 SEE ALSO

L<Maypole>,L<Maypole::HTTPD>

=cut

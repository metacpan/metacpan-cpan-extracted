package HTTP::MessageParser;

use strict;
use warnings;

our $VERSION = 0.3;

use Carp qw[];

{
    require Sub::Exporter;

    my $exporter = sub {
        my ( $class, $method ) = @_;
        return sub { return $class->$method(@_) };
    };

    my %exports = map { $_ => $exporter } qw(
        parse_headers
        parse_request
        parse_request_line
        parse_response
        parse_response_line
        parse_version
    );

    Sub::Exporter->import( -setup => { exports => \%exports } );
}

{
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec2.html#sec2.2
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2
    # http://lists.w3.org/Archives/Public/ietf-http-wg/2004JanMar/thread.html#50
    # http://lists.w3.org/Archives/Public/ietf-http-wg/2005AprJun/0016.html

    my $CRLF     = qr/\x0D?\x0A/;
    my $LWS      = qr/$CRLF[\x09\x20]|[\x09\x20]/;
    my $TEXT     = qr/[\x20-\xFF]/;
    my $Token    = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;
    my $Header   = qr/($Token+)$LWS*:$LWS*((?:$TEXT|$LWS)*)$CRLF/;
    my $Version  = qr/HTTP\/[0-9]+\.[0-9]+/;
    my $Request  = qr/(?:$CRLF)*($Token+)[\x09\x20]+([\x21-\xFF]+)(?:[\x09\x20]+($Version))?$CRLF/;
    my $Response = qr/($Version)[\x09\x20]+([0-9]{3})[\x09\x20]+($TEXT*)$CRLF/;

    sub parse_request ($$) {
        my $class  = shift;
        my $string = ref $_[0] ? shift : \( my $copy = shift );

        my @request = $class->parse_request_line($string);
        my $version = $class->parse_version( $request[2] );
        my $headers = [];

        if ( $version >= 1000 ) {

            $headers = $class->parse_headers($string);

            $$string =~ s/^$CRLF//o
              or Carp::croak('Bad Request');
        }
        else {

            $$string eq ''
              or Carp::croak('Bad Request');
        }

        return ( @request, $headers, $string );
    }

    sub parse_request_line ($$) {
        my $class  = shift;
        my $string = ref $_[0] ? shift : \( my $copy = shift );

        $$string =~ s/^$Request//o
          or Carp::croak('Bad Request-Line');

        return ( $1, $2, $3 || 'HTTP/0.9' );
    }

    sub parse_response ($$) {
        my $class  = shift;
        my $string = ref $_[0] ? shift : \( my $copy = shift );

        my @response = $class->parse_response_line($string);
        my $headers  = $class->parse_headers($string);

        $$string =~ s/^$CRLF//o
          or Carp::croak('Bad Response');

        return ( @response, $headers, $string );
    }

    # Yes, I know it's status_line, but response_line fits better with API ;)
    sub parse_response_line ($$) {
        my $class  = shift;
        my $string = ref $_[0] ? shift : \( my $copy = shift );

        $$string =~ s/^$Response//o
          or Carp::croak('Bad Status-Line');

        return ( $1, $2, $3 );
    }

    sub parse_headers ($$) {
        my $class  = shift;
        my $string = ref $_[0] ? shift : \( my $copy = shift );

        my @headers = ();

        while ( $$string =~ s/^$Header//o ) {
            push @headers, lc $1 => $2;
        }

        foreach ( @headers ) {
            s/$LWS+/\x20/og;
            s/^$LWS//o;
            s/$LWS$//o;
        }

        return wantarray ? @headers : \@headers;
    }

    sub parse_version ($$) {
        my $class  = shift;
        my $string = shift;

        $string =~ m/^HTTP\/([0-9]+)\.([0-9]+)$/
          or Carp::croak('Bad HTTP-Version');

        my $major  = $1;
        my $minor  = $2;
        my $number = $major * 1000 + $minor;

        return wantarray ? ( $major, $minor ) : $number;
    }
}

1;

__END__

=head1 NAME

HTTP::MessageParser - Parse HTTP Messages

=head1 SYNOPSIS

    use HTTP::MessageParser;

    my ( $message, @request );

    while ( my $line = $client->getline ) {
        next if !$message && $line eq "\x0D\x0A"; # RFC 2616 4.1
        $message .= $line;
        last if $message =~ /\x0D\x0A\x0D\x0A$/;
    }

    eval {
        @request = HTTP::MessageParser->parse_request($message);
    };

    if ( $@ ) {
        # 400 Bad Request
    }

    # ...

=head1 DESCRIPTION

Parse HTTP/1.0 and HTTP/1.1 Messages.

=head1 METHODS

=over 4

=item parse_headers( $string )

    my @headers = HTTP::MessageParser->parse_headers($string);
    my $headers = HTTP::MessageParser->parse_headers($string);

Parses C<Message Headers>. C<field-name>'s are lowercased. Leading and trailing C<LWS> is
removed. C<LWS> occurring between C<field-content> are replaced with a single C<SP>.
Takes one argument, a string or a reference to a string, if it's a reference it will be consumed.

=item parse_request( $string )

    my ( $Method, $Request_URI, $HTTP_Version, $Headers, $Body )
      = HTTP::MessageParser->parse_request($string);

Parses a Request. Expects a C<Request-Line> followed by zero more header fields and an empty line.
Content occurring after end of header fields is returned as a string reference, C<$Body>.
Takes one argument, a string or a reference to a string, if it's a reference it will be consumed.

Throws an exception upon failure.

=item parse_request_line( $string )

    my ( $Method, $Request_URI, $HTTP_Version )
      = HTTP::MessageParser->parse_request_line($string);

Parses a C<Request-Line>. Any leading C<CRLF> is ignored. Takes one argument,
a string or a reference to a string, if it's a reference it will be consumed.

Throws an exception upon failure.

=item parse_response( $string )

    my ( $HTTP_Version, $Status_Code, $Reason_Phrase, $Headers, $Body )
      = HTTP::MessageParser->parse_response($string);

Parses a Response. Expects a C<Status-Line> followed by zero more header fields and an empty line.
Content occurring after end of header fields is returned as a string reference, C<$Body>.
Takes one argument, a string or a reference to a string, if it's a reference it will be consumed.

Throws an exception upon failure.

=item parse_response_line( $string )

    my ( $HTTP_Version, $Status_Code, $Reason_Phrase )
      = HTTP::MessageParser->parse_response_line($string);

Parses a C<Status-Line>. Takes one argument, a string or a reference to a
string, if it's a reference it will be consumed.

Throws an exception upon failure.

=item parse_version( $string )

    my ( $major, $minor ) = HTTP::MessageParser->parse_version($string);
    my $version = HTTP::MessageParser->parse_version($string);

Parses a C<HTTP-Version> string. In scalar context it returns a version number
( C<major * 1000 + minor> ). In list context it returns C<major> and C<minor> as two
separate integers.

Throws an exception upon failure.

=back

=head1 EXPORTS

Nothing by default. Following subroutines can be exported:

=over 4

=item parse_headers

=item parse_request

=item parse_request_line

=item parse_response

=item parse_response_line

=item parse_version

=back

=head1 SEE ALSO

L<http://www.w3.org/Protocols/rfc2616/rfc2616.html>

L<HTTP::Request>

L<HTTP::Response>

L<HTTP::Message>

L<HTTP::Parser>

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

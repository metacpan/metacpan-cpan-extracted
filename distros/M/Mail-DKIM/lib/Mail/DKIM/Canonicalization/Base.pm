package Mail::DKIM::Canonicalization::Base;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: base class for canonicalization methods

# Copyright 2005-2007 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use base 'Mail::DKIM::MessageParser';
use Carp;

sub new {
    my $class = shift;
    return $class->new_object(@_);
}

sub init {
    my $self = shift;
    $self->SUPER::init;

    unless ( $self->{output}
        || $self->{output_fh}
        || $self->{output_digest}
        || $self->{buffer} )
    {
        $self->{result} = '';
        $self->{buffer} = \$self->{result};
    }
}

sub output {
    my $self = shift;

    # my ($output) = @_;  # optimized away for speed

    my $out_fh = $self->{output_fh};
    if ($out_fh) {
        print $out_fh @_;
    }
    if ( my $digest = $self->{output_digest} ) {
        $digest->add(@_);
    }
    if ( my $out_obj = $self->{output} ) {
        $out_obj->PRINT(@_);
    }
    if ( my $buffer = $self->{buffer} ) {
        ${ $self->{buffer} } .= $_[0];
    }

    # this supports Debug_Canonicalization
    if ( my $debug = $self->{Debug_Canonicalization} ) {
        if ( UNIVERSAL::isa( $debug, 'SCALAR' ) ) {
            $$debug .= $_[0];
        }
        elsif ( UNIVERSAL::isa( $debug, 'GLOB' ) ) {
            print $debug @_;
        }
        elsif ( UNIVERSAL::isa( $debug, 'IO::Handle' ) ) {
            $debug->print(@_);
        }
    }
}

sub result {
    my $self = shift;
    return $self->{result};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Canonicalization::Base - base class for canonicalization methods

=head1 VERSION

version 1.20220520

=head1 SYNOPSIS

  # canonicalization results get output to STDOUT
  my $method = new Mail::DKIM::Canonicalization::relaxed(
                    output_fh => *STDOUT,
                    Signature => $dkim_signature);

  # add headers
  $method->add_header("Subject: this is the subject\015\012");
  $method->finish_header(Headers => \@all_headers);

  # add body
  $method->add_body("This is the body.\015\012");
  $method->add_body("Another two lines\015\012of the body.\015\012");
  $method->finish_body;

  # this adds the signature to the end
  $method->finish_message;

=head1 CONSTRUCTOR

Use the new() method of the desired canonicalization implementation class
to construct a canonicalization object. E.g.

  my $method = new Mail::DKIM::Canonicalization::relaxed(
                    output_fh => *STDOUT,
                    Signature => $dkim_signature);

The constructors accept these arguments:

=over

=item Signature

(Required) Provide the DKIM signature being constructed (if the message is
being signed), or the DKIM signature being verified (if the message is
being verified). The canonicalization method either writes parameters to
the signature, or reads parameters from the signature (e.g. the h= tag).

=item output

If specified, the canonicalized message will be passed to this object with
the PRINT method.

=item output_digest

If specified, the canonicalized message will be added to this digest.
(Uses the add() method.)

=item output_fh

If specified, the canonicalized message will be written to this file
handle.

=back

If none of the output parameters are specified, then the canonicalized
message is appended to an internal buffer. The contents of this buffer
can be accessed using the result() method.

=head1 METHODS

=head2 add_body() - feeds part of the body into the canonicalization

  $method->add_body("This is the body.\015\012");
  $method->add_body("Another two lines\015\012of the body.\015\012");

The body should be fed one or more "lines" at a time.
I.e. do not feed part of a line.

=head2 finish_header() - called when the header has been completely parsed

  $method->finish_header(Headers => \@all_headers);

Formerly the canonicalization object would only get the header data
through successive invocations of add_header(). However, that required
the canonicalization object to store a copy of the entire header so
that it could choose the order in which headers were fed to the digest
object. This is inefficient use of memory, since a message with many
signatures may use many canonicalization objects and each
canonicalization object has its own copy of the header.

The headers array is an array of one element per header field, with
the headers not processed/canonicalized in any way.

=head2 result()

  my $result = $method->result;

If you did not specify an object or handle to send the output to, the
result of the canonicalization is stored in the canonicalization method
itself, and can be accessed using this method.

=head1 SEE ALSO

L<Mail::DKIM>

=head1 AUTHORS

=over 4

=item *

Jason Long <jason@long.name>

=item *

Marc Bradshaw <marc@marcbradshaw.net>

=item *

Bron Gondwana <brong@fastmailteam.com> (ARC)

=back

=head1 THANKS

Work on ensuring that this module passes the ARC test suite was
generously sponsored by Valimail (https://www.valimail.com/)

=head1 COPYRIGHT AND LICENSE

=over 4

=item *

Copyright (C) 2013 by Messiah College

=item *

Copyright (C) 2010 by Jason Long

=item *

Copyright (C) 2017 by Standcore LLC

=item *

Copyright (C) 2020 by FastMail Pty Ltd

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

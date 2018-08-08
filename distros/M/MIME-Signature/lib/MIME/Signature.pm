package MIME::Signature;

use 5.014;
use warnings;

our $VERSION = '0.11';

use Carp qw(croak);
use Encode qw(decode encode encode_utf8);
use MIME::Parser;

sub _decoded_body {
    my $entity = shift;
    my $body   = $entity->bodyhandle->as_string;
    if ( my $charset = $entity->head->mime_attr('content-type.charset') ) {
        $body = decode $charset, $body;
    }
    $body;
}

sub _replace_body {
    my ( $entity, $body ) = @_;
    $body .= "\n" if $body !~ /\n\z/;
    my $encoded_body;
    {
        my $encoding_ok;
        if ( my $charset = $entity->head->mime_attr('content-type.charset') ) {
            $encoding_ok = 1;
            $encoded_body = encode $charset, $body,
              sub { undef $encoding_ok; '' };
        }
        unless ($encoding_ok) {
            my $head = $entity->head;
            $head->mime_attr( 'Content-Type', 'text/plain' )
              unless $head->mime_attr('content-type');
            $head->mime_attr( 'content-type.charset' => 'UTF-8' );
            $encoded_body = encode_utf8($body);
        }
    }
    my $fh = $entity->bodyhandle->open('w') or die "Open body: $!\n";

    # Avoid "SMTP cannot transfer messages with partial final lines. (#5.6.2)":
    $fh->print($encoded_body);

    $fh->close or die "Cannot replace body: $!\n";
}

sub enriched {
    my $self = shift;
    if (@_) {
        $self->{enriched} = shift;
    }
    elsif ( defined wantarray ) {
        if ( !defined $self->{enriched} && defined( my $plain = $self->plain ) )
        {
            $self->{enriched} = $plain =~ s/</<</gr =~ s/(\n+)/$1\n/gr;
        }
        $self->{enriched};
    }
}

sub enriched_delimiter {
    my $self = shift;
    $self->{enriched_delimiter} = shift if @_;
    $self->{enriched_delimiter};
}

sub html {
    my $self = shift;
    if (@_) {
        $self->{html} = shift;
    }
    elsif ( defined wantarray ) {
        if ( !defined $self->{html} && defined( my $plain = $self->plain ) ) {
            require HTML::Entities
              and HTML::Entities->import('encode_entities')
              unless defined &encode_entities;
            $self->{html} =
              join( '<br>', split /\n/, encode_entities($plain) ) . "\n";
        }
        $self->{html};
    }
}

sub html_delimiter {
    my $self = shift;
    $self->{html_delimiter} = shift if @_;
    $self->{html_delimiter};
}

sub plain {
    my $self = shift;
    $self->{plain} = shift if @_;
    $self->{plain};
}

sub plain_delimiter {
    my $self = shift;
    $self->{plain_delimiter} = shift if @_;
    $self->{plain_delimiter};
}

sub unsign {
    my $self = shift;
    $self->{unsign} = shift if @_;
    $self->{unsign};
}

sub _signature {
    my ( $self, $type ) = @_;
    defined( my $signature = $self->$type ) or return;
    my $delimiter_method = $type . '_delimiter';
    $self->$delimiter_method . $signature;
}

sub handler_multipart_alternative {    # add trailer to all parts
    my ( $self, $entity ) = @_;
    $self->append($_) for my @parts = $entity->parts;
    @parts;
}

sub handler_multipart_mixed {          # append trailer as separate part
    my ( $self, $entity ) = @_;
    require Encode and Encode->import('encode_utf8')
      unless defined &encode_utf8;
    $entity->add_part(
        my $e = MIME::Entity->build(
            Top      => 0,
            Charset  => 'UTF-8',
            Encoding => '-SUGGEST',
            Type     => grep( lc $_->mime_type eq 'text/html', $entity->parts )
            ? ( 'text/html', Data => encode_utf8( $self->_signature('html') ) )
            : grep( lc $_->mime_type eq 'text/enriched', $entity->parts )
            ? (
                'text/enriched',
                Data => encode_utf8( $self->_signature('enriched') )
              )
            : (
                'text/plain', Data => encode_utf8( $self->_signature('plain') )
            )
        )
    );
}

sub handler_multipart_related {    # add trailer to the first part
    my ( $self, $entity ) = @_;
    $self->append( ( $entity->parts )[0] );
}

sub handler_multipart_signed {
    my ( $self, $entity ) = @_;
    return unless $self->unsign;

    {                              # Inspired by MIME::Entity->make_singlepart:

        my ($part) = my @parts = $entity->parts;
        croak 'Invalid multipart/signed containing '
          . @parts . ' part'
          . ( @parts != 1 && 's' )
          if @parts != 2;

        # Get rid of all our existing content info:
        /^content-/i and $entity->head->delete($_) for $entity->head->tags;

        # Populate ourselves with any content info from the part:
        for my $tag ( grep /^content-/i, $part->head->tags ) {
            $entity->head->add( $tag, $_ ) for $part->head->get($tag);
        }

        # Save reconstructed header, replace our guts, and restore header:
        my $new_head = $entity->head;
        %$entity = %$part;    # shallow copy is ok!
        $entity->head($new_head);
    }

    $self->append($entity);
}

sub handler_text_enriched {    # append trailer
    my ( $self, $entity ) = @_;
    _replace_body( $entity,
        _decoded_body($entity) . $self->_signature('enriched') );
}

sub handler_text_html {        # append trailer to <body>
    my ( $self, $entity ) = @_;
    my $body = _decoded_body($entity);
    require HTML::Parser;
    my $new_body;
    my $parser = HTML::Parser->new(
        end_h => [
            sub {
                my ( $text, $tagname ) = @_;
                $new_body .= $self->_signature('html') if lc $tagname eq 'body';
                $new_body .= $text;
            },
            'text,tagname'
        ],
        default_h => [ sub { $new_body .= shift }, 'text' ],
    );
    $parser->parse($body);
    _replace_body( $entity, $new_body );
}

sub handler_text_plain {    # append trailer
    my ( $self, $entity ) = @_;
    _replace_body( $entity,
        _decoded_body($entity) . $self->_signature('plain') );
}

sub new {
    my $package = shift;
    $package = ref $package if length ref $package;
    croak 'Invalid number of arguments to ->new' if @_ % 2;
    my $self = bless {
        enriched_delimiter => "\n\n-- \n",
        html_delimiter     => '<hr>',
        plain_delimiter    => "\n\n-- \n",
      },
      $package;
    while ( my $method = shift ) {
        $self->$method(shift);
    }
    $self;
}

sub entity {
    my $self = shift;
    $self->{entity} = shift if @_;
    $self->{entity};
}

sub parser {
    my $self = shift;
    if (@_) {
        $self->{parser} = shift;
    }
    elsif ( !$self->{parser} ) {
        for ( $self->{parser} ) {
            $_ = MIME::Parser->new;
            $_->tmp_to_core(1);
            $_->output_to_core(1);
        }
    }
    $self->{parser};
}

sub parse {
    my $self = shift;
    $self->{entity} = $self->parser->parse(@_);
}

sub parse_data {
    my $self = shift;
    $self->{entity} = $self->parser->parse_data(@_);
}

sub parse_open {
    my $self = shift;
    $self->{entity} = $self->parser->parse_open(@_);
}

sub parse_two {
    my $self = shift;
    $self->{entity} = $self->parser->parse_two(@_);
}

sub append {
    my $self = shift;
    my $entity = shift || $self->{entity}
      or croak( 'You must first hand in an e-mail message'
          . ' before trying to append a signature.' );
    ( my $handler_method =
          'handler_' . lc( my $mime_type = $entity->mime_type ) ) =~ y!/!_!;
    $self->can($handler_method) and $self->$handler_method($entity)
      or croak "Cannot handle $mime_type messages";
    $entity;
}

__END__

=head1 NAME

MIME::Signature - appends signature to mail messages

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $ms = MIME::Signature->new(
        plain => 'Das ist der Rand von Ostermundigen.' 
    );
    $ms->parse( \*STDIN );
    $ms->append;
    $ms->entity->print;

Or, alternatively:

    my $ms = MIME::Signature->new(
        plain => 'Das ist der Rand von Ostermundigen.' 
    );
    my $entity = MIME::Parser->new->parse( \*STDIN );
    $ms->append($entity);
    $entity->print;

Or even:

    MIME::Signature->new(
        plain => 'Das ist der Rand von Ostermundigen.',
        parse => \*STDIN
    )->append->print;

=head1 DESCRIPTION

This module appends a signature to an e-mail messages.
It tries its best to cope with any encodings and MIME structures.

=head1 METHODS

=over 4

=item ->new

Constructs a L<MIME::Signature> object.
You may optionally pass additional method =E<gt> argument pairs
as a shortcut to calling the respective methods.
(This only works for methods which require exactly one argument.)

=item ->plain

Sets and/or returns the plaintext version of the signature to append.

=item ->enriched

Sets and/or returns the L<enriched text|https://tools.ietf.org/html/rfc1896>
version of the signature to append.

=item ->html

Sets and/or returns the HTML version of the signature to append.
If not given, will be automatically deducted from the plaintext version.

=item ->plain_delimiter

Sets and/or returns the delimiter to insert before the signature within a
text/plain part.

Default: C<\n\n-- \n>

=item ->enriched_delimiter

Sets and/or returns the delimiter to insert before the signature within a
L<text/enriched|https://tools.ietf.org/html/rfc1896> part.

Default: C<\n\n-- \n>

=item ->html_delimiter

Sets and/or returns the delimiter to insert before the signature within a
text/html part.

Default: C<< <hr> >>

=item ->parse

=item ->parse_data

=item ->parse_open

=item ->parse_two

These are wrappers to the methods of the same name from L<MIME::Parser>
to ease parsing of mail messages.
Will store the L<MIME::Entity> returned in the L<MIME::Signature> object
for further processing.

=item ->parser

Gets or sets the L<MIME::Parser> object used by the C<parse*> methods
mentioned above.
If you do not supply a parser object, MIME::Signature will create one
by itself as needed.

=item ->entity

Gets or sets the L<MIME::Entity> object which stores the mail message.

=item ->unsign

When given a true value as argument, multipart/signed parts of the message
will automatically be removed during L<< ->append >>, so that we can append
a (text) signature without invalidating the (cryptographic) signature.

=item ->append

Appends the signature to the L<MIME::Entity> stored in the
L<MIME::Signature> object.
Alternatively you may supply a L<MIME::Entity> object yourself
which will then I<not> be stored in the L<MIME::Signature> object.
In any case, the L<MIME::Entity> object will be modified as the
signature is added.
Returns the L<MIME::Entity> object.

This method will die if it cannot append a signature,
e.g. because the mail does not contain a text/plain and/or text/html part
or if the text is enclosed in a multipart/signed part and you have not
specified L<< /->unsign >>.

=back

=head1 SUBCLASSING

The module uses the following methods to handle the respective MIME types.
You may overwrite them and/or provide likely named additional handler methods
to deal with other types.

The method gets passed the MIME part in question.
It should alter this part if it wants to append the signature.
It is expected to return a boolean value to signal success.
That is, L<< /->append >> will croak when a handler method returns false.

=over 4

=item ->handler_multipart_alternative

appends the signature to any contained part

=item ->handler_multipart_mixed

appends another part with the signature inside

=item ->handler_multipart_related

appends the signature to the first contained part

=item ->handler_multipart_signed

If L<< /-unsign >> is set, replaces the multipart/signed part
by the first part it contains.

Returns false otherwise.

=item ->handler_text_html

appends the HTML version of the signature to the end of the C<< <body> >>

=item ->handler_text_enriched

appends the enriched text version of the signature

=item ->handler_text_plain

appends the plain version of the signature

=back

=head1 AUTHOR

Martin H. Sluka, C<< <fany@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mime-signature at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MIME-Signature>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MIME::Signature

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MIME-Signature>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MIME-Signature>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/MIME-Signature>

=item * Search CPAN

L<https://metacpan.org/release/MIME-Signature>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Martin H. Sluka.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of MIME::Signature

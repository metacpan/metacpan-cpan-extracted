package HTTP::Body;
$HTTP::Body::VERSION = '1.23';
use strict;

use Carp       qw[ ];

our $TYPES = {
    'application/octet-stream'          => 'HTTP::Body::OctetStream',
    'application/x-www-form-urlencoded' => 'HTTP::Body::UrlEncoded',
    'multipart/form-data'               => 'HTTP::Body::MultiPart',
    'multipart/related'                 => 'HTTP::Body::XFormsMultipart',
    'application/xml'                   => 'HTTP::Body::XForms',
    'application/json'                  => 'HTTP::Body::OctetStream',
};

require HTTP::Body::OctetStream;
require HTTP::Body::UrlEncoded;
require HTTP::Body::MultiPart;
require HTTP::Body::XFormsMultipart;
require HTTP::Body::XForms;

use HTTP::Headers;
use HTTP::Message;

=head1 NAME

HTTP::Body - HTTP Body Parser

=head1 SYNOPSIS

    use HTTP::Body;
    
    sub handler : method {
        my ( $class, $r ) = @_;

        my $content_type   = $r->headers_in->get('Content-Type');
        my $content_length = $r->headers_in->get('Content-Length');
        
        my $body   = HTTP::Body->new( $content_type, $content_length );
        my $length = $content_length;

        while ( $length ) {

            $r->read( my $buffer, ( $length < 8192 ) ? $length : 8192 );

            $length -= length($buffer);
            
            $body->add($buffer);
        }
        
        my $uploads     = $body->upload;     # hashref
        my $params      = $body->param;      # hashref
        my $param_order = $body->param_order # arrayref
        my $body        = $body->body;       # IO::Handle
    }

=head1 DESCRIPTION

HTTP::Body parses chunks of HTTP POST data and supports
application/octet-stream, application/json, application/x-www-form-urlencoded,
and multipart/form-data.

Chunked bodies are supported by not passing a length value to new().

It is currently used by L<Catalyst>, L<Dancer>, L<Maypole>, L<Web::Simple> and
L<Jedi>.

=head1 NOTES

When parsing multipart bodies, temporary files are created to store any
uploaded files.  You must delete these temporary files yourself after
processing them, or set $body->cleanup(1) to automatically delete them at
DESTROY-time.

With version 1.23, we have changed the basic behavior of how temporary files
are prepared for uploads.  The extension of the file is no longer transferred
to the temporary file, the extension will always be C<.upload>.  We have also
introduced variables that make it possible to set the behavior as required.

=over 4

=item $HTTP::Body::MultiPart::file_temp_suffix

This is the extension that is given to all multipart files. The default
setting here is C<.upload>.  If you want the old behavior from before version
1.23, simply undefine the value here.

=item $HTTP::Body::MultiPart::basename_regexp

This is the regexp used to determine out the file extension.  This is of
course no longer necessary, unless you undefine
C<HTTP::Body::MultiPart::file_temp_suffix>.

=item $HTTP::Body::MultiPart::file_temp_template

This gets passed through to the L<File::Temp> TEMPLATE parameter.  There is no
special default in our module.

=item %HTTP::Body::MultiPart::file_temp_parameters

In this hash you can add up custom settings for the L<File::Temp> invokation.
Those override every other setting.

=back

=head1 METHODS

=over 4 

=item new 

Constructor. Takes content type and content length as parameters,
returns a L<HTTP::Body> object.

=cut

sub new {
    my ( $class, $content_type, $content_length ) = @_;

    unless ( @_ >= 2 ) {
        Carp::croak( $class, '->new( $content_type, [ $content_length ] )' );
    }

    my $type;
    my $earliest_index;
    foreach my $supported ( keys %{$TYPES} ) {
        my $index = index( lc($content_type), $supported );
        if ($index >= 0 && (!defined $earliest_index || $index < $earliest_index)) {
            $type           = $supported;
            $earliest_index = $index;
        }
    }

    my $body = $TYPES->{ $type || 'application/octet-stream' };

    my $self = {
        cleanup        => 0,
        buffer         => '',
        chunk_buffer   => '',
        body           => undef,
        chunked        => !defined $content_length,
        content_length => defined $content_length ? $content_length : -1,
        content_type   => $content_type,
        length         => 0,
        param          => {},
        param_order    => [],
        state          => 'buffering',
        upload         => {},
        part_data      => {},
        tmpdir         => File::Spec->tmpdir(),
    };

    bless( $self, $body );

    return $self->init;
}

sub DESTROY {
    my $self = shift;
    
    if ( $self->{cleanup} ) {
        my @temps = ();
        for my $upload ( values %{ $self->{upload} } ) {
            push @temps, map { $_->{tempname} || () }
                ( ref $upload eq 'ARRAY' ? @{$upload} : $upload );
        }
        
        unlink map { $_ } grep { -e $_ } @temps;
    }
}

=item add

Add string to internal buffer. Will call spin unless done. returns
length before adding self.

=cut

sub add {
    my $self = shift;
    
    if ( $self->{chunked} ) {
        $self->{chunk_buffer} .= $_[0];
        
        while ( $self->{chunk_buffer} =~ m/^([\da-fA-F]+).*\x0D\x0A/ ) {
            my $chunk_len = hex($1);
            
            if ( $chunk_len == 0 ) {
                # Strip chunk len
                $self->{chunk_buffer} =~ s/^([\da-fA-F]+).*\x0D\x0A//;
                
                # End of data, there may be trailing headers
                if (  my ($headers) = $self->{chunk_buffer} =~ m/(.*)\x0D\x0A/s ) {
                    if ( my $message = HTTP::Message->parse( $headers ) ) {
                        $self->{trailing_headers} = $message->headers;
                    }
                }
                
                $self->{chunk_buffer} = '';
                
                # Set content_length equal to the amount of data we read,
                # so the spin methods can finish up.
                $self->{content_length} = $self->{length};
            }
            else {
                # Make sure we have the whole chunk in the buffer (+CRLF)
                if ( length( $self->{chunk_buffer} ) >= $chunk_len ) {
                    # Strip chunk len
                    $self->{chunk_buffer} =~ s/^([\da-fA-F]+).*\x0D\x0A//;
                    
                    # Pull chunk data out of chunk buffer into real buffer
                    $self->{buffer} .= substr $self->{chunk_buffer}, 0, $chunk_len, '';
                
                    # Strip remaining CRLF
                    $self->{chunk_buffer} =~ s/^\x0D\x0A//;
                
                    $self->{length} += $chunk_len;
                }
                else {
                    # Not enough data for this chunk, wait for more calls to add()
                    return;
                }
            }
            
            unless ( $self->{state} eq 'done' ) {
                $self->spin;
            }
        }
        
        return;
    }
    
    my $cl = $self->content_length;

    if ( defined $_[0] ) {
        $self->{length} += length( $_[0] );
        
        # Don't allow buffer data to exceed content-length
        if ( $self->{length} > $cl ) {
            $_[0] = substr $_[0], 0, $cl - $self->{length};
            $self->{length} = $cl;
        }
        
        $self->{buffer} .= $_[0];
    }

    unless ( $self->state eq 'done' ) {
        $self->spin;
    }

    return ( $self->length - $cl );
}

=item body

accessor for the body.

=cut

sub body {
    my $self = shift;
    $self->{body} = shift if @_;
    return $self->{body};
}

=item chunked

Returns 1 if the request is chunked.

=cut

sub chunked {
    return shift->{chunked};
}

=item cleanup

Set to 1 to enable automatic deletion of temporary files at DESTROY-time.

=cut

sub cleanup {
    my $self = shift;
    $self->{cleanup} = shift if @_;
    return $self->{cleanup};
}

=item content_length

Returns the content-length for the body data if known.
Returns -1 if the request is chunked.

=cut

sub content_length {
    return shift->{content_length};
}

=item content_type

Returns the content-type of the body data.

=cut

sub content_type {
    return shift->{content_type};
}

=item init

return self.

=cut

sub init {
    return $_[0];
}

=item length

Returns the total length of data we expect to read if known.
In the case of a chunked request, returns the amount of data
read so far.

=cut

sub length {
    return shift->{length};
}

=item trailing_headers

If a chunked request body had trailing headers, trailing_headers will
return an HTTP::Headers object populated with those headers.

=cut

sub trailing_headers {
    return shift->{trailing_headers};
}

=item spin

Abstract method to spin the io handle.

=cut

sub spin {
    Carp::croak('Define abstract method spin() in implementation');
}

=item state

Returns the current state of the parser.

=cut

sub state {
    my $self = shift;
    $self->{state} = shift if @_;
    return $self->{state};
}

=item param

Get/set body parameters.

=cut

sub param {
    my $self = shift;

    if ( @_ == 2 ) {

        my ( $name, $value ) = @_;

        if ( exists $self->{param}->{$name} ) {
            for ( $self->{param}->{$name} ) {
                $_ = [$_] unless ref($_) eq "ARRAY";
                push( @$_, $value );
            }
        }
        else {
            $self->{param}->{$name} = $value;
        }

        push @{$self->{param_order}}, $name;
    }

    return $self->{param};
}

=item upload

Get/set file uploads.

=cut

sub upload {
    my $self = shift;

    if ( @_ == 2 ) {

        my ( $name, $upload ) = @_;

        if ( exists $self->{upload}->{$name} ) {
            for ( $self->{upload}->{$name} ) {
                $_ = [$_] unless ref($_) eq "ARRAY";
                push( @$_, $upload );
            }
        }
        else {
            $self->{upload}->{$name} = $upload;
        }
    }

    return $self->{upload};
}

=item part_data

Just like 'param' but gives you a hash of the full data associated with the
part in a multipart type POST/PUT.  Example:

    {
      data => "test",
      done => 1,
      headers => {
        "Content-Disposition" => "form-data; name=\"arg2\"",
        "Content-Type" => "text/plain"
      },
      name => "arg2",
      size => 4
    }

=cut

sub part_data {
    my $self = shift;

    if ( @_ == 2 ) {

        my ( $name, $data ) = @_;

        if ( exists $self->{part_data}->{$name} ) {
            for ( $self->{part_data}->{$name} ) {
                $_ = [$_] unless ref($_) eq "ARRAY";
                push( @$_, $data );
            }
        }
        else {
            $self->{part_data}->{$name} = $data;
        }
    }

    return $self->{part_data};
}

=item tmpdir 

Specify a different path for temporary files.  Defaults to the system temporary path.

=cut

sub tmpdir {
    my $self = shift;
    $self->{tmpdir} = shift if @_;
    return $self->{tmpdir};
}

=item param_order

Returns the array ref of the param keys in the order how they appeared on the body

=cut

sub param_order {
    return shift->{param_order};
}

=back

=head1 SUPPORT

Since its original creation this module has been taken over by the Catalyst
development team. If you need general support using this module:

IRC:

    Join #catalyst on irc.perl.org.

Mailing Lists:

    http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/catalyst

If you want to contribute patches, these will be your
primary contact points:

IRC:

    Join #catalyst-dev on irc.perl.org.

Mailing Lists:

    http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/catalyst-dev

=head1 AUTHOR

Christian Hansen, C<chansen@cpan.org>

Sebastian Riedel, C<sri@cpan.org>

Andy Grundman, C<andy@hybridized.org>

=head1 CONTRIBUTORS

Simon Elliott C<cpan@papercreatures.com>

Kent Fredric C<kentnl@cpan.org>

Christian Walde C<walde.christian@gmail.com>

Torsten Raudssus C<torsten@raudssus.de>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;

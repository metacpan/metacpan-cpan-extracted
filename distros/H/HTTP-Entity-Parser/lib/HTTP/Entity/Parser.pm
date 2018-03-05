package HTTP::Entity::Parser;

use 5.008001;
use strict;
use warnings;
use Stream::Buffered;
use Module::Load;

our $VERSION = "0.21";

our $BUFFER_LENGTH = 65536;

our %LOADED;
our @DEFAULT_PARSER = qw/
    OctetStream
    UrlEncoded
    MultiPart
    JSON
/;
for my $parser ( @DEFAULT_PARSER ) {
    load "HTTP::Entity::Parser::".$parser;
    $LOADED{"HTTP::Entity::Parser::".$parser} = 1;
}

sub new {
    my $class = shift;
    my %args = (
        buffer_length => $BUFFER_LENGTH,
        @_,
    );
    bless [ [], $args{buffer_length} ], $class;
}

sub register {
    my ($self,$content_type, $klass, $opts) = @_;
    if ( !$LOADED{$klass} ) {
        load $klass;
        $LOADED{$klass} = 1;
    }
    push @{$self->[0]}, [$content_type, $klass, $opts];
}

sub parse {
    my ($self, $env) = @_;

    my $buffer_length = $self->[1];
    my $ct = $env->{CONTENT_TYPE};
    if (!$ct) {
        # No Content-Type
        return ([], []);
    }

    my $parser;
    for my $handler (@{$self->[0]}) {
        if ( $ct eq $handler->[0] || index($ct, $handler->[0]) == 0) {
            $parser = $handler->[1]->new($env, $handler->[2]);
            last;
        }
    }

    if ( !$parser ) {
        $parser = HTTP::Entity::Parser::OctetStream->new();
    }


    my $input = $env->{'psgi.input'};
    if (!$input) {
        # no input
        return ([], []);
    }

    my $buffer;
    if ($env->{'psgix.input.buffered'}) {
        # Just in case if input is read by middleware/apps beforehand
        $input->seek(0, 0);
    } else {
        $buffer = Stream::Buffered->new();
    }

    my $chunked = do { no warnings; lc delete $env->{HTTP_TRANSFER_ENCODING} eq 'chunked' };
    if ( my $cl = $env->{CONTENT_LENGTH} ) {
        my $spin = 0;
        while ($cl > 0) {
            $input->read(my $chunk, $cl < $buffer_length ? $cl : $buffer_length);
            my $read = length $chunk;
            $cl -= $read;
            $parser->add($chunk);
            $buffer->print($chunk) if $buffer;
            if ($read == 0 && $spin++ > 2000) {
                Carp::croak "Bad Content-Length: maybe client disconnect? ($cl bytes remaining)";
            }
        }
    }
    elsif ($chunked) {
        my $chunk_buffer = '';
        my $length;
        my $spin = 0;
        DECHUNK: while(1) {
            $input->read(my $chunk, $buffer_length);
            my $read = length $chunk;
            if ($read == 0 ) {
                Carp::croak "Malformed chunked request" if $spin++ > 2000;
                next;
            }
            $chunk_buffer .= $chunk;
            while ( $chunk_buffer =~ s/^(([0-9a-fA-F]+).*\015\012)// ) {
                my $trailer   = $1;
                my $chunk_len = hex $2;
                if ($chunk_len == 0) {
                    last DECHUNK;
                } elsif (length $chunk_buffer < $chunk_len + 2) {
                    $chunk_buffer = $trailer . $chunk_buffer;
                    last;
                }
                my $loaded = substr $chunk_buffer, 0, $chunk_len, '';
                $parser->add($loaded);
                $buffer->print($loaded);
                $chunk_buffer =~ s/^\015\012//;
                $length += $chunk_len;
            }
        }
        $env->{CONTENT_LENGTH} = $length;
    }

    if ($buffer) {
        $env->{'psgix.input.buffered'} = 1;
        $env->{'psgi.input'} = $buffer->rewind;
    } else {
        $input->seek(0, 0);
    }

    $parser->finalize();
}

1;
__END__

=encoding utf-8

=head1 NAME

HTTP::Entity::Parser - PSGI compliant HTTP Entity Parser

=head1 SYNOPSIS

    use HTTP::Entity::Parser;

    my $parser = HTTP::Entity::Parser->new;
    $parser->register('application/x-www-form-urlencoded','HTTP::Entity::Parser::UrlEncoded');
    $parser->register('multipart/form-data','HTTP::Entity::Parser::MultiPart');
    $parser->register('application/json','HTTP::Entity::Parser::JSON');

    sub app {
        my $env = shift;
        my ( $params, $uploads) = $parser->parse($env);
    }

=head1 DESCRIPTION

HTTP::Entity::Parser is a PSGI-compliant HTTP Entity parser. This module also is compatible
with L<HTTP::Body>. Unlike HTTP::Body, HTTP::Entity::Parser reads HTTP entities from
PSGI's environment C<< $env->{'psgi.input'} >> and parses it.
This module supports application/x-www-form-urlencoded, multipart/form-data and application/json.

=head1 METHODS

=over 4

=item new( buffer_length => $length:Intger)

Create the instance.

=over 4

=item buffer_length

The buffer length that HTTP::Entity::Parser reads from psgi.input. 16384 by default.

=back

=item register($content_type:String, $class:String, $opts:HashRef)

Register parser class.

  $parser->register('application/x-www-form-urlencoded','HTTP::Entity::Parser::UrlEncoded');
  $parser->register('multipart/form-data','HTTP::Entity::Parser::MultiPart');
  $parser->register('application/json','HTTP::Entity::Parser::JSON');

If the request content_type matches the registered type, HTTP::Entity::Parser uses the registered
parser class. If content_type does not match any registered type, HTTP::Entity::Parser::OctetStream is used.

=item parse($env:HashRef)

parse HTTP entities from PSGI's env.

  my ( $params:ArrayRef, $uploads:ArrayRef) = $parser->parse($env);

C<$param> is a key-value pair list.

   my ( $params, $uploads) = $parser->parse($env);
   my $body_parameters = Hash::MultiValue->new(@$params);

C<$uploads> is an ArrayRef of HashRef.

   my ( $params, $uploads) = $parser->parse($env);
   warn Dumper($uploads->[0]);
   {
       "name" => "upload", #field name
       "headers" => [
           "Content-Type" => "application/octet-stream",
           "Content-Disposition" => "form-data; name=\"upload\"; filename=\"hello.pl\""
       ],
       "size" => 78, #size of upload content
       "filename" => "hello.png", #original filename in the client
       "tempname" => "/tmp/XXXXX", # path to the temporary file where uploaded file is saved
   }

When used with L<Plack::Request::Upload>:

   my ( $params, $uploads) = $parser->parse($env);
    my $upload_hmv = Hash::MultiValue->new();
    while ( my ($k,$v) = splice @$uploads, 0, 2 ) {
        my %copy = %$v;
        $copy{headers} = HTTP::Headers::Fast->new(@{$v->{headers}});
        $upload_hmv->add($k, Plack::Request::Upload->new(%copy));
    }

=back

=head1 PARSERS

=over 4

=item OctetStream

Default parser, This parser does not parse entity, always return empty list.

=item UrlEncoded

For C<application/x-www-form-urlencoded>. It is used for HTTP POST without file upload

=item MultiPart

For C<multipart/form-data>. It is used for HTTP POST contains file upload.

MultiPart parser use L<HTTP::MultiPartParser>.

=item JSON

For C<application/json>. This parser decodes JSON body automatically.

It is convenient to use with Ajax forms.

=back

=head1 WHAT'S DIFFERENT FROM HTTP::Body

HTTP::Entity::Parser accept PSGI's env and read body from it.

HTTP::Entity::Parser is able to choose parsers by the instance, HTTP::Body requires to modify global variables.

=head1 SEE ALSO

=over 4

=item L<HTTP::Body>

=item L<HTTP::MultiPartParser>

=item L<Plack::Request>

=item L<WWW::Form::UrlEncoded>

HTTP::Entity::Parser uses this for parse application/x-www-form-urlencoded

=back

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

This module is based on tokuhirom's code, see L<https://github.com/plack/Plack/pull/434>

=cut

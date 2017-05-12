package Maypole::Headers;
use base 'HTTP::Headers';

use strict;
use warnings;

our $VERSION = "1." . sprintf "%04d", q$Rev: 376 $ =~ /: (\d+)/;

sub get {
    shift->header(shift);
}

sub set {
    shift->header(@_);
}

*add = \&push; # useful for Apache::Session::Wrapper support

sub push {
    shift->push_header(@_);
}

sub init {
    shift->init_header(@_);
}

sub remove {
    shift->remove_header(@_);
}

sub field_names {
    shift->header_field_names(@_);
}

1;

=pod

=head1 NAME

Maypole::Headers - Convenience wrapper around HTTP::Headers

=head1 SYNOPSIS

    use Maypole::Headers;

    $r->headers_out(Maypole::Headers->new); # Note, automatic in Maypole
    $r->headers_out->set('Content-Base' => 'http://localhost/maypole');
    $r->headers_out->push('Set-Cookie' => $cookie->as_string);
    $r->headers_out->push('Set-Cookie' => $cookie2->as_string);

    print $r->headers_out->as_string;

=head1 DESCRIPTION

A convenience wrapper around C<HTTP::Headers>. Additional methods are provided
to make the mutators less repetitive and wordy. For example:

    $r->headers_out->header(Content_Base => $r->config->uri_base);

can be written as:

    $r->headers_out->set(Content_Base => $r->config->uri_base);

=head1 METHODS

All the standard L<HTTP::Headers> methods, plus the following:

=over

=item get($header)

Get the value of a header field.

An alias to C<HTTP::Headers-E<gt>header>

=item set($header =C<gt> $value, ...)

Set the value of one or more header fields

An alias to C<HTTP::Headers-E<gt>header>

=item push($header =C<gt> $value)

Add a value to the field named C<$header>. Previous values are maintained.

An alias to C<HTTP::Headers-E<gt>push_header>

=item add

Alias to C<push> - useful for C<Apache::Session::Wrapper> support, in CGI mode.

=item init($header =C<gt> $value)

Set the value for the field named C<$header>, but only if that header is
currently undefined.

An alias to C<HTTP::Headers-E<gt>init_header>

=item remove($header, ...)

Remove one of more headers

An alias to C<HTTP::Headers-E<gt>remove_header>

=item field_names()

Returns a list of distinct header names

An alias to C<HTTP::Headers-E<gt>header_field_names>

=back

=head1 SEE ALSO

L<HTTP::Headers>

=head1 AUTHOR

Simon Flack

=cut

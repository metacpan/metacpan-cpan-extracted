use strict;
use warnings;
package MetaCPAN::Client::Pod;
# ABSTRACT: A Pod object
$MetaCPAN::Client::Pod::VERSION = '2.028000';
use Moo;
use Carp;

use MetaCPAN::Client::Types qw< Str >;

has request => (
    is       => 'ro',
    handles  => [qw<ua fetch post ssearch>],
    required => 1,
);

has name => ( is => 'ro', required => 1 );

has url_prefix => (
    is  => 'ro',
    isa => Str,
);

my @known_formats = qw<
    html plain x_pod x_markdown
>;

foreach my $format (@known_formats) {
    has $format => (
        is      => 'ro',
        lazy    => 1,
        default => sub {
            my $self = shift;
            return $self->_request( $format );
        },
    );
}

sub _request {
    my $self  = shift;
    my $ctype = shift || "plain";
    $ctype =~ s/_/-/;

    my $url = 'pod/' . $self->name . '?content-type=text/' . $ctype;
    $self->url_prefix and $url .= '&url_prefix=' . $self->url_prefix;

    return $self->request->fetch($url);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::Client::Pod - A Pod object

=head1 VERSION

version 2.028000

=head1 SYNOPSIS

  use strict;
  use warnings;
  use MetaCPAN::Client;

  my $pod = MetaCPAN::Client->new->pod('Moo');

  print $pod->html;

=head1 DESCRIPTION

A MetaCPAN pod entity object.

=head1 ATTRIBUTES

=head2 request

A L<MetaCPAN::Client::Request> object (created in L<MetaCPAN::Client>)

=head2 name

The name of the module (probably always the value passed to the pod() method)

=head2 url_prefix

Prefix to be passed through the url_prefix query parameter to the 'pod' endpoint

=head2 x_pod

The raw pod extracted from the file.

=head2 html

Formatted as an HTML chunk (No <html>...<body>)

=head2 x_markdown

Converted to Markdown.

=head2 plain

Formatted as plain text.

Get the plaintext version of the documentation

  $pod = MetaCPAN::Client->new->pod( "MetaCPAN::Client" );
  print $pod->plain;

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Mickey Nasriachi <mickey@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Zipper;
$Zipper::VERSION = '0.72';
use strict;
use warnings;

use Exporter 'import';
use URI::Escape qw(uri_escape);

use Developer::Dashboard::Codec qw(encode_payload decode_payload);

our @EXPORT = qw(zip unzip _cmdx _cmdp __cmdx acmdx Ajax);

# zip($text)
# Encodes a text payload to the legacy token structure.
# Input: plain text string.
# Output: hash with raw and url token values.
sub zip {
    my ($text) = @_;
    return if !defined $text || $text eq '';
    my $raw = encode_payload($text);
    return {
        raw => $raw,
        url => uri_escape($raw),
    };
}

# unzip($token)
# Decodes a legacy token payload back to text.
# Input: encoded token string.
# Output: plain text string.
sub unzip {
    my ($token) = @_;
    return if !defined $token || $token eq '';
    return decode_payload($token);
}

# acmdx(%args)
# Builds a legacy ajax/action URL bundle for encoded code execution.
# Input: path, type, target, label, code, and optional app/save/base_url values.
# Output: hash with token, url, forward, and html keys.
sub acmdx {
    my %args = @_;
    my $type = $args{type} || 'text';
    my $path = $args{path} || '/ajax';
    my $code = $args{code} // '';
    my $base = $args{base_url} || '';
    my $token = zip($code) || { raw => '', url => '' };
    my $query = sprintf '%s?token=%s&type=%s', $path, $token->{url}, uri_escape($type);
    my $url = $base ? $base . $query : $query;
    return {
        token   => $token,
        url     => { tokenised => $url, app => $args{app} || $url },
        forward => [ $path => { token => $token->{raw}, type => $type } ],
        html    => sprintf( q{<a href="%s" target="%s">%s</a>}, $url, ( $args{target} || '_blank' ), ( $args{label} || 'Click Here' ) ),
    };
}

# Ajax(%args)
# Prints a legacy config-binding script for an encoded ajax endpoint.
# Input: jvar, type, and code values.
# Output: hide marker string.
sub Ajax {
    my %args = @_;
    die "jvar is required" if !$args{jvar};
    my $ajax = acmdx(
        %args,
        path => '/ajax',
        type => $args{type} || 'json',
    );
    my ( $root, $path ) = split /\./, $args{jvar}, 2;
    $path ||= '';
    print sprintf qq{<script>set_chain_value(%s,'%s','%s')</script>}, $root, $path, $ajax->{url}{tokenised};
    return 'HIDE-THIS';
}

# __cmdx($type, $code)
# Returns a shell pipeline string that decodes an encoded payload.
# Input: type string and code string.
# Output: shell command string.
sub __cmdx {
    my ( $type, $code ) = @_;
    my $token = zip($code) || { raw => '' };
    return "printf '%s' " . quotemeta( $token->{raw} ) . " | base64 -d | gunzip";
}

# _cmdx($type, $code)
# Returns legacy shell execution tuple values.
# Input: type string and code string.
# Output: list of shell tuple values.
sub _cmdx {
    my ( $type, $code ) = @_;
    my $switch = $type eq 'perl' ? '-e' : '-c';
    return ( $type, $switch, __cmdx( $type, $code ) );
}

# _cmdp($type, $code)
# Returns legacy shell pipeline tuple values.
# Input: type string and code string.
# Output: list of pipeline tuple values.
sub _cmdp {
    my ( $type, $code ) = @_;
    return ( __cmdx( $type, $code ), $type );
}

1;

__END__

=head1 NAME

Zipper - legacy token encoding and ajax URL compatibility helpers

=head1 SYNOPSIS

  use Zipper qw(zip unzip Ajax);
  my $token = zip("print qq{ok\\n};");

=head1 DESCRIPTION

This module recreates the small token and ajax helper surface expected by
older bookmark code without carrying forward any project-specific logic.

=head1 FUNCTIONS

=head2 zip, unzip, acmdx, Ajax, __cmdx, _cmdx, _cmdp

Encode and decode token payloads and generate legacy-style ajax links.

=cut

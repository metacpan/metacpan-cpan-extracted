package EZID;

use Modern::Perl;

use Encode;
use HTTP::Request::Common;
use LWP::UserAgent;
use URI::Escape;

our $VERSION = '0.02';

sub new {
    my ($class, $args) = @_;

    $args //= {};

    return unless (ref $args eq 'HASH');

    my $self = {
        _username => $args->{username},
        _password => $args->{password},
    };

    return bless $self, $class;
}

sub _parse {
    my ($data) = @_;

    return map {
        map {
            my $a = $_;
            $a =~ s/%([0-9A-F]{2})/pack("C", hex($1))/egi;
            $a
        } split(/: /, $_, 2)
    } split(/\n/, $data)
}

sub get {
    my ($self, $identifier) = @_;

    return unless $identifier;
    my $response;
    my %metadata;

    my $ua = LWP::UserAgent->new;
    my $r = $ua->get("http://ezid.cdlib.org/id/$identifier");
    if ($r->is_success) {
        $response = { _parse($r->decoded_content) };
    } else {
        $self->{_error_msg} = $r->decoded_content;
    }

    return $response;
}

sub _escape {
  (my $s = $_[0]) =~ s/([%:\r\n])/uri_escape($1)/eg;
  return $s;
}

sub create {
    my ($self, $identifier, $metadata) = @_;

    $metadata //= {};

    my $content = encode("UTF-8", join("\n",
            map { escape($_) . ": " . escape($metadata->{$_}) } keys %$metadata));

    my $ua = LWP::UserAgent->new;
    $ua->credentials("ezid.cdlib.org:443", "EZID", $self->{_username},
        $self->{_password});
    my $r = $ua->request(PUT "https://ezid.cdlib.org/id/$identifier",
        'Content-Type' => "text/plain; charset=UTF-8",
        'Content' => $content);

    my $response;
    if ($r->is_success) {
        $response = { _parse($r->decoded_content) };
    } else {
        $self->{_error_msg} = $r->decoded_content;
    }

    return $response;
}

sub error_msg {
    my ($self) = @_;

    return $self->{_error_msg};
}

1;
__END__

=head1 NAME

EZID - Perl interface to EZID API - http://ezid.cdlib.org/doc/apidoc.html

=head1 SYNOPSIS

  use EZID;

  my $ezid = new EZID({username => $username, password => $password});
  $ezid->create($identifier, $metadata);
  $metadata = $ezid->get($identifier);

=head1 DESCRIPTION

Perl interface to EZID API - http://ezid.cdlib.org/doc/apidoc.html

=head1 AUTHOR

Julian Maurice E<lt>julian.maurice@biblibre.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Julian Maurice

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

package File::KDBX::Key::ChallengeResponse;
# ABSTRACT: A challenge-response key

use warnings;
use strict;

use File::KDBX::Error;
use File::KDBX::Util qw(:class);
use namespace::clean;

extends 'File::KDBX::Key';

our $VERSION = '0.905'; # VERSION

sub init {
    my $self = shift;
    my $primitive = shift or throw 'Missing key primitive';

    $self->{responder} = $primitive;

    return $self->hide;
}


sub raw_key {
    my $self = shift;
    if (@_) {
        my $challenge = shift // '';
        # Don't challenge if we already have the response.
        return $self->SUPER::raw_key if $challenge eq ($self->{challenge} // '');
        $self->_set_raw_key($self->challenge($challenge, @_));
        $self->{challenge} = $challenge;
    }
    $self->SUPER::raw_key;
}


sub challenge {
    my $self = shift;

    my $responder = $self->{responder} or throw 'Cannot issue challenge without a responder';
    return $responder->(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Key::ChallengeResponse - A challenge-response key

=head1 VERSION

version 0.905

=head1 SYNOPSIS

    use File::KDBX::Key::ChallengeResponse;

    my $responder = sub {
        my $challenge = shift;
        ...;    # generate a response based on a secret of some sort
        return $response;
    };
    my $key = File::KDBX::Key::ChallengeResponse->new($responder);

=head1 DESCRIPTION

A challenge-response key is kind of like multifactor authentication, except you don't really I<authenticate>
to a KDBX database because it's not a service. Specifically it would be the "what you have" component. It
assumes there is some device that can store a key that is only known to the owner of a database. A challenge
is made to the device and the response generated based on the key is used as the raw key.

Inherets methods and attributes from L<File::KDBX::Key>.

This is a generic implementation where a responder subroutine is provided to provide the response. There is
also L<File::KDBX::Key::YubiKey> which is a subclass that allows YubiKeys to be responder devices.

=head1 METHODS

=head2 raw_key

    $raw_key = $key->raw_key;
    $raw_key = $key->raw_key($challenge);

Get the raw key which is the response to a challenge. The response will be saved so that subsequent calls
(with or without the challenge) can provide the response without challenging the responder again. Only one
response is saved at a time; if you call this with a different challenge, the new response is saved over any
previous response.

=head2 challenge

    $response = $key->challenge($challenge, @options);

Issue a challenge and get a response, or throw if the responder failed to provide one.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

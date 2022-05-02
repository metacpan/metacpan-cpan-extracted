package File::KDBX::Cipher::CBC;
# ABSTRACT: A CBC block cipher mode encrypter/decrypter

use warnings;
use strict;

use Crypt::Mode::CBC;
use File::KDBX::Error;
use File::KDBX::Util qw(:class);
use namespace::clean;

extends 'File::KDBX::Cipher';

our $VERSION = '0.901'; # VERSION

has key_size => 32;
sub iv_size     { 16 }
sub block_size  { 16 }

sub encrypt {
    my $self = shift;

    my $mode = $self->{mode} ||= do {
        my $m = Crypt::Mode::CBC->new($self->algorithm);
        $m->start_encrypt($self->key, $self->iv);
        $m;
    };

    return join('', map { $mode->add(ref $_ ? $$_ : $_) } grep { defined } @_);
}

sub decrypt {
    my $self = shift;

    my $mode = $self->{mode} ||= do {
        my $m = Crypt::Mode::CBC->new($self->algorithm);
        $m->start_decrypt($self->key, $self->iv);
        $m;
    };

    return join('', map { $mode->add(ref $_ ? $$_ : $_) } grep { defined } @_);
}

sub finish {
    my $self = shift;
    return '' if !$self->{mode};
    my $out = $self->{mode}->finish;
    delete $self->{mode};
    return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Cipher::CBC - A CBC block cipher mode encrypter/decrypter

=head1 VERSION

version 0.901

=head1 SYNOPSIS

    use File::KDBX::Cipher::CBC;

    my $cipher = File::KDBX::Cipher::CBC->new(algorithm => $algo, key => $key, iv => $iv);

=head1 DESCRIPTION

A subclass of L<File::KDBX::Cipher> for encrypting and decrypting data using the CBC block cipher mode.

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

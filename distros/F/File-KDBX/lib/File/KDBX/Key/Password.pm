package File::KDBX::Key::Password;
# ABSTRACT: A password key

use warnings;
use strict;

use Crypt::Digest qw(digest_data);
use Encode qw(encode);
use File::KDBX::Error;
use File::KDBX::Util qw(:class erase);
use namespace::clean;

extends 'File::KDBX::Key';

our $VERSION = '0.905'; # VERSION

sub init {
    my $self = shift;
    my $primitive = shift // throw 'Missing key primitive';

    $self->_set_raw_key(digest_data('SHA256', encode('UTF-8', $primitive)));

    return $self->hide;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Key::Password - A password key

=head1 VERSION

version 0.905

=head1 SYNOPSIS

    use File::KDBX::Key::Password;

    my $key = File::KDBX::Key::Password->new($password);

=head1 DESCRIPTION

A password key is as simple as it sounds. It's just a password or passphrase.

Inherets methods and attributes from L<File::KDBX::Key>.

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

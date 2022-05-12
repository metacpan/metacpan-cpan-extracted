package File::KDBX::Loader::Raw;
# ABSTRACT: A no-op loader that doesn't do any parsing

use warnings;
use strict;

use File::KDBX::Util qw(:class);
use namespace::clean;

extends 'File::KDBX::Loader';

our $VERSION = '0.903'; # VERSION

sub _read {
    my $self = shift;
    my $fh   = shift;

    $self->_read_body($fh);
}

sub _read_body {
    my $self = shift;
    my $fh   = shift;

    $self->_read_inner_body($fh);
}

sub _read_inner_body {
    my $self = shift;
    my $fh   = shift;

    my $content = do { local $/; <$fh> };
    $self->kdbx->raw($content);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Loader::Raw - A no-op loader that doesn't do any parsing

=head1 VERSION

version 0.903

=head1 SYNOPSIS

    use File::KDBX::Loader;

    my $kdbx = File::KDBX::Loader->load_file('file.kdbx', $key, inner_format => 'Raw');
    print $kdbx->raw;

=head1 DESCRIPTION

A typical KDBX file is made up of an outer section (with headers) and an inner section (with the body). The
inner section is usually loaded using L<File::KDBX::Loader::XML>, but you can use the
B<File::KDBX::Loader::Raw> loader to not parse the body at all and just get the raw body content. This can be
useful for debugging or creating KDBX files with arbitrary content (see L<File::KDBX::Dumper::Raw>).

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

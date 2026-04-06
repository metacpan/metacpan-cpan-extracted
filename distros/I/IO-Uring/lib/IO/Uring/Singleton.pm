package IO::Uring::Singleton;
$IO::Uring::Singleton::VERSION = '0.013';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = 'ring';

use IO::Uring;

our $size = 128;
our %arguments;

my $ring;
sub ring {
    return $ring //= IO::Uring->new($size, %arguments);
}

1;

#ABSTRACT: A shared singleton uring

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Uring::Singleton - A shared singleton uring

=head1 VERSION

version 0.013

=head1 SYNOPSIS

 use IO::Uring::Singleton;
 my $ring = IO::Uring::Singleton::ring();

=head2 DESCRIPTION

This module provides a ring singleton to share between different event loop systems.

=head1 FUNCTIONS

=head2 ring

This returns always returns the same ring, that will be created the first time the function is called.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

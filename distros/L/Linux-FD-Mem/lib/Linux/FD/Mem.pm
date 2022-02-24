package Linux::FD::Mem;
$Linux::FD::Mem::VERSION = '0.001';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

# ABSTRACT: memory file descriptors

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::FD::Mem - memory file descriptors

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Linux::FD::Mem
 
 my $fh = Linux::FD::Mem->new();

=head1 METHODS

=head2 new($name)

This creates an anonymous file and returns a file descriptor that refers to it. The file behaves like a regular file, and so can be modified, truncated, memory-mapped, and so on. However, unlike a regular file, it lives in RAM and has a volatile backing storage. Once all references to the file are dropped, it is automatically released. Anonymous memory is used for all backing pages of the file. Therefore, files created by this module have the same semantics as other anonymous memory allocations such as those allocated using L<File::Map|File::Map>'s C<map_anonymous>.

The name supplied in C<$name> is used as a filename and will be displayed as the target of the corresponding symbolic link in the directory /proc/self/fd/. The displayed name is always prefixed with memfd: and serves only for debugging purposes. Names do not affect the behavior of the file descriptor, and as such multiple files can have the same name without any side effects.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

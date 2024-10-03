# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for reading and writing ValueFile files

package File::ValueFile;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.01;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ValueFile - module for reading and writing ValueFile files

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use File::ValueFile;

This module only provides some global functionality.
For reading and writing ValueFiles see L<File::ValueFile::Simple::Reader> and L<File::ValueFile::Simple::Writer>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

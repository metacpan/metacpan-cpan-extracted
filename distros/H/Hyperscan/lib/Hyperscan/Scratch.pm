package Hyperscan::Scratch;
$Hyperscan::Scratch::VERSION = '0.04';
# ABSTRACT: scratch class

use strict;
use warnings;

use Hyperscan;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hyperscan::Scratch - scratch class

=head1 VERSION

version 0.04

=head2 METHODS

=head3 clone()

Allocate a scratch space that is a clone of an existing scratch space.

L<hs_clone_scratch|https://intel.github.io/hyperscan/dev-reference/api_files.html#c.hs_clone_scratch>

=head3 size()

Provides the size of the given scratch space.

L<hs_scratch_size|https://intel.github.io/hyperscan/dev-reference/api_files.html#c.hs_scratch_size>

=head1 AUTHOR

Mark Sikora <marknsikora@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Mark Sikora.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

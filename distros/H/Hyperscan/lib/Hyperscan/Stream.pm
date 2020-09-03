package Hyperscan::Stream;
$Hyperscan::Stream::VERSION = '0.03';
# ABSTRACT: stream class

use strict;
use warnings;

use Hyperscan;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hyperscan::Stream - stream class

=head1 VERSION

version 0.03

=head2 METHODS

=head3 copy()

Duplicate the given stream. The new stream will have the same state as the
original including the current stream offset.

L<hs_copy_stream|https://intel.github.io/hyperscan/dev-reference/api_files.html#c.hs_copy_stream>

=head3 reset( $flags, $scratch, $callback )

Reset a stream to an initial state.

L<hs_reset_stream|https://intel.github.io/hyperscan/dev-reference/api_files.html#c.hs_reset_stream>

=head3 scan( $data, $flags, $scratch, $callback )

Write data to be scanned to the opened stream.

L<hs_scan_stream|https://intel.github.io/hyperscan/dev-reference/api_files.html#c.hs_scan_stream>

=head1 AUTHOR

Mark Sikora <marknsikora@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Mark Sikora.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

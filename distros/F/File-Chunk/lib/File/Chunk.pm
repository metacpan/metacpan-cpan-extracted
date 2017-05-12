# ABSTRACT: Read/Write file handles that are stored as seperate, size-limited files on disk

package File::Chunk;
{
  $File::Chunk::VERSION = '0.0035';
}
BEGIN {
  $File::Chunk::AUTHORITY = 'cpan:DHARDISON';
}
use Moose;
use Bread::Board::Declare;

use namespace::autoclean;


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

File::Chunk - Read/Write file handles that are stored as seperate, size-limited files on disk

=head1 VERSION

version 0.0035

=head1 AUTHOR

Dylan William Hardison <dylan@hardison.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

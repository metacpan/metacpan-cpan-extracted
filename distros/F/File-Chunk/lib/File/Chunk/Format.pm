# ABSTRACT: Role for findings (TODO: generating) chunk file names.

package File::Chunk::Format;
{
  $File::Chunk::Format::VERSION = '0.0035';
}
BEGIN {
  $File::Chunk::Format::AUTHORITY = 'cpan:DHARDISON';
}
use Moose::Role;
use namespace::autoclean;



requires 'find_chunk_files', 'decode_chunk_filename', 'encode_chunk_filename';


1;

__END__

=pod

=head1 NAME

File::Chunk::Format - Role for findings (TODO: generating) chunk file names.

=head1 VERSION

version 0.0035

=head1 METHODS

=head2 find_chunk_files($dir)

Return a callback iterator that successively returns chunk filenames in $dir as L<Path::Class::File> objects.

=head1 AUTHOR

Dylan William Hardison <dylan@hardison.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

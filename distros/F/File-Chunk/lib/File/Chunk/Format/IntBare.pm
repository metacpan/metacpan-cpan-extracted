# ABSTRACT: Chunk files stored as plain integers.

package File::Chunk::Format::IntBare;
{
  $File::Chunk::Format::IntBare::VERSION = '0.0035';
}
BEGIN {
  $File::Chunk::Format::IntBare::AUTHORITY = 'cpan:DHARDISON';
}
use Moose;
use namespace::autoclean;

use MooseX::Params::Validate;
use MooseX::Types::Path::Class 'File';

use Path::Class::Rule;

with 'File::Chunk::Format::Regexp';

sub chunk_regexp { qr/^\d+$/ }

around decode_chunk_filename => sub {
    my ($method, $self, @args) = @_;
    int($self->$method(@args));
};

sub encode_chunk_filename {
    my $self = shift;
    my ($i) = pos_validated_list(\@_, { isa => 'Int' });

    sprintf "%d", $i;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

File::Chunk::Format::IntBare - Chunk files stored as plain integers.

=head1 VERSION

version 0.0035

=head1 AUTHOR

Dylan William Hardison <dylan@hardison.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

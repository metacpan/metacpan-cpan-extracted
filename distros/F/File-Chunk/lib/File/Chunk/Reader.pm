# ABSTRACT: Provide getline() interface to a file chunk directory.
package File::Chunk::Reader;
{
  $File::Chunk::Reader::VERSION = '0.0035';
}
BEGIN {
  $File::Chunk::Reader::AUTHORITY = 'cpan:DHARDISON';
}
use Moose;

use File::Chunk::Iter;
use Carp;
use IO::Handle::Util 'io_to_glob';
use MooseX::Types::Moose 'ArrayRef';
use MooseX::Types::Path::Class 'Dir';
use MooseX::SetOnce;

use namespace::clean;

use overload ( '*{}' => \&io_to_glob, fallback => 1 );

has 'file_dir' => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
);

has 'binmode' => (
    traits    => ['SetOnce'],
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_binmode',
);

has 'format' => (
    is       => 'ro',
    does     => 'File::Chunk::Format',
    required => 1,
);

has '_chunk_iter' => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'File::Chunk::Iter',
    lazy     => 1,
    builder  => '_build_chunk_iter',
    handles  => {
        _chunk         => [ at => 0 ],
        _next_chunk    => 'next',
        _is_last_chunk => 'is_last',
    },
);

sub _build_chunk_iter {
    my $self = shift;
    my $filename_iter = $self->format->find_chunk_files( $self->file_dir );
    my $chunk_iter    = sub {
        my $fn = $filename_iter->();
        if ($fn) {
            my $fh = $fn->openr;
            $fh->binmode( $self->binmode ) if $self->has_binmode;
            return $fh;
        }
        else {
            return undef;
        }
    };

    return File::Chunk::Iter->new(iter => $chunk_iter, look_ahead => 2);
}


sub eof {
    my $self = shift;
    
    return 1 if $self->_chunk->eof && $self->_is_last_chunk;
    return '';
}


sub getline {
    my $self = shift;

    for (;;) {
        return undef unless defined $self->_chunk;
        my $line = $self->_chunk->getline;
        return $line if defined $line;
        return undef if $self->_is_last_chunk;
        $self->_next_chunk;
    }
}


sub print {
    croak "print not implemented";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

File::Chunk::Reader - Provide getline() interface to a file chunk directory.

=head1 VERSION

version 0.0035

=head1 METHODS

=head2 eof()

returns 1 if there are more chunks to read or we're still reading from the last chunk,
returns '' otherwise. (see perldoc -f eof)

=head2 getline

Returns a newline as L<File::Handle>->getline would.

=head2 print

Throws an error. See L<File::Chunk::Writer> for print()

=head1 AUTHOR

Dylan William Hardison <dylan@hardison.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

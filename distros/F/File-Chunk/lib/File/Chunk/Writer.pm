# ABSTRACT: Provide line-based chunk file writing as a file-handle-like object.

package File::Chunk::Writer;
{
  $File::Chunk::Writer::VERSION = '0.0035';
}
BEGIN {
  $File::Chunk::Writer::AUTHORITY = 'cpan:DHARDISON';
}
use Moose;

use Carp;
use English '$RS', '$OFS', '$ORS';
use IO::Handle::Util 'io_to_glob';
use List::MoreUtils 'natatime';
use MooseX::SetOnce;
use MooseX::Types::Path::Class 'Dir';
use YAML::XS;

use namespace::clean;

use overload ( '*{}' => \&io_to_glob, fallback => 1 );

has 'binmode' => (
    traits    => ['SetOnce'],
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_binmode',
);

has 'chunk_dir' => (
    is       => 'ro',
    isa      => Dir,
    coerce   => 1,
    required => 1,
);

has 'chunk_line_limit' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'format' => (
    is       => 'ro',
    does     => 'File::Chunk::Format',
    required => 1,
);

has '_chunk_id' => (
    init_arg => undef,
    traits   => ['Number'],
    is       => 'ro',
    isa      => 'Int',
    default  => 0,
    handles  => { _next_chunk_id => [ add => 1 ] },
);

has '_chunk_line_count' => (
    traits  => ['Number'],
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    handles => {
        _inc_chunk_line_count   => [ add => 1 ],
        _reset_chunk_line_count => [ set => 0 ],
    },
);

has '_chunk' => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'IO::Handle',
    lazy     => 1,
    builder  => '_build_chunk',
    clearer  => '_next_chunk',
    handles  => { _print => 'print' },
);

after '_next_chunk' => sub { shift->_reset_chunk_line_count };

sub _build_chunk {
    my $self = shift;

    my $filename = $self->chunk_dir->file( $self->format->encode_chunk_filename( $self->_next_chunk_id - 1 ) );

    my $fh = $filename->openw;
    if ($self->has_binmode) {
        $fh->binmode($self->binmode);
    }
    return $fh;
}

sub _chunk_is_full {
    my $self = shift;

    return $self->_chunk_line_count >= $self->chunk_line_limit;
}

sub getline {
    croak "getline not implemented";
}

sub print {
    my $self  = shift;
    my $rs    = defined($RS) ? quotemeta($RS) : "\n";
    my @lines = split(/($rs)/, join($OFS // '' , @_) . ( $ORS // '') );

    while (my ($line, $eol) = splice @lines, 0, 2) {
        $self->_inc_chunk_line_count if defined $eol;
        $self->_print($line, $eol ? ($eol) : ());
        $self->_next_chunk if $self->_chunk_is_full;
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

File::Chunk::Writer - Provide line-based chunk file writing as a file-handle-like object.

=head1 VERSION

version 0.0035

=head1 AUTHOR

Dylan William Hardison <dylan@hardison.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
